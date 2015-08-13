library force.transformer;

import 'package:barback/barback.dart';

import 'dart:async';
import 'dart:io';
import 'dart:mirrors' as mirrors;

import 'package:force/force_serverside.dart';
import 'package:barback/barback.dart';
import 'package:analyzer/analyzer.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/error.dart';
import 'package:analyzer/src/generated/parser.dart';
import 'package:analyzer/src/generated/scanner.dart';
import 'package:source_maps/refactor.dart';
import 'package:source_span/source_span.dart' show SourceFile;

List compilers = new List();
CompilerTransformer mainCombo;

class AnnotationTransformer extends Transformer {
  final BarbackSettings _settings;

  AnnotationTransformer.asPlugin(this._settings);

  String get allowedExtensions => ".dart";

  Future apply(Transform transform) async {
      var id = transform.primaryInput.id;
      var url = id.path.startsWith('lib/')
      ? 'package:${id.package}/${id.path.substring(4)}'
      : id.path;

      return transform.primaryInput.readAsString().then((String content) {
          FileCompiler compiler = new FileCompiler.fromString(id, content);
          CompilerTransformer compilerTransformer = new CompilerTransformer(compiler, transform, url, id);

          if (compiler.isMain) {
             for(var compilerTransformerFromList in compilers) {
               compilerTransformer.compiler.addAll(compilerTransformerFromList.compiler.receivables);
             }
             mainCombo = compilerTransformer;
          } else {
            print ('not main! $url');
            if (mainCombo != null) {
               mainCombo.compiler.addAll(compiler.receivables);
               print('go transform main again! ');
               mainCombo.transformate();
             } else {
               compilers.add(compilerTransformer);
             }
          }

          compilerTransformer.transformate();
      });

  }
}

class CompilerTransformer {
  FileCompiler compiler;
  Transform transform;
  String url;
  var id;

  CompilerTransformer(this.compiler, this.transform, this.url, this.id);

  void transformate() {
    var code = compiler.build(url);

    print( 'Are we having edits? ${compiler.hasEdits}' );

    if (compiler.hasEdits) {
      transform.addOutput(new Asset.fromString(id, code));
    } else {
      transform.addOutput(transform.primaryInput);
    }
  }
}

class FileCompiler {

  final CharSequenceReader reader;
  final Editor editor;

  Parser parser;
  Scanner scanner;
  CompilationUnit compilationUnit;

  Expression main;

  bool isMain;

  bool _hasEdits;

  bool get hasEdits => _hasEdits;

  final List<ClassDeclaration> receivables = <ClassDeclaration>[];

  FileCompiler(String path)
  : this.fromString(path, new File(path).readAsStringSync());

  FileCompiler.fromString(String path, String code)
  : editor = new Editor(path, code),
  reader = new CharSequenceReader(code) {
    scanner = new Scanner(null, reader, this);
    parser = new Parser(null, this);

    compilationUnit = parser.parseCompilationUnit(scanner.tokenize());

    // _dartsonPrefix = findDartsonImportName();
    _findReceivables();

    main = _findMainMethod();
    isMain = main != null;
  }

  void _findReceivables() {
    receivables.addAll(compilationUnit.declarations
      .where((m) => m is ClassDeclaration &&
      m.metadata
      .any((n) =>
        n.name.name == "Receivable"
      ))
      // Erasing the type of the returned where iterable to allow checked-mode
      .map((cd) {
        return cd;
      }));

    if (receivables.length > 0) {
      _hasEdits = true;
    }
  }

  void addAll(List newReceivables) {
    receivables.addAll(newReceivables);

    if (receivables.length > 0) {
      _hasEdits = true;
    }
  }

  String build(String url) {
    var length = receivables.length;
    print ( 'build this $url -> $length' );
    _addAllReceivables();

    var builder = editor.editor.commit();
    builder.build(url);
    return builder.text;
  }

  void _addAllReceivables() {
    //
    ForceClientName forceClientName =_findForceInstance();
    print( 'go and loop over all the receivables' );
    receivables.forEach((ClassDeclaration receivable) {
      print ( 'receivable ' + receivable.name.name );
      // print ( forceClientName.forceInstanceName );
        if (forceClientName!=null) {
            var classDef = _buildClassDefinition(receivable, forceClientName.forceInstanceName);
            var entityMap = _buildReceiverList(receivable);
            var registerMethods = _buildRegisterMethod(forceClientName.forceInstanceName, receivable.name.name.toLowerCase(), entityMap);

            Expression expression = forceClientName.expression, editPosition = expression.endToken.end + 1;
            if (!_expressionInMethod(expression)){
                expression = main;
                editPosition = expression.endToken.end -2;
                print( 'expression is not in METHOD??? What now ... ' );
            } else {
                print( 'expression is in method !!!' );
            }
            // MethodDeclaration mainMethod = _findMainMethod();
            print('\n${classDef}\n${registerMethods}\n');

            editor.editor.edit(editPosition, editPosition,
            '\n${classDef}\n${registerMethods}\n');
        }
    });
  }

  bool _expressionInMethod(Expression expression) {
    if (expression.parent is MethodDeclaration || expression.parent is FunctionDeclaration) {
      return true;
    } else if (expression.parent == null) {
      return false;
    } else {
      return _expressionInMethod(expression.parent);
    }
  }

  ForceClientName _findForceInstance() {
    ForceClientName forceName;
    for (var m in compilationUnit.declarations) {
      if (m is InstanceCreationExpression) {
        forceName = _findForceInstanceByExpression(m, forceName);
      } else {
        forceName = _findForceInstanceByChild(m, forceName);
      }
    }
    return forceName;
  }

  ForceClientName _findForceInstanceByChild(m, forceClientName) {
    for (var child in m.childEntities) {
      if (!(child is Token)) {
        if (child is InstanceCreationExpression) {
          forceClientName = _findForceInstanceByExpression(child, forceClientName);
        } else {
          forceClientName = _findForceInstanceByChild(child, forceClientName);
        }
      }
    }
    return forceClientName;
  }

  ForceClientName _findForceInstanceByExpression(InstanceCreationExpression ice, forceClientName) {
    if (ice.constructorName.toSource() == "ForceClient") {
      if (ice.parent is VariableDeclaration) {
        VariableDeclaration vd = ice.parent;

        forceClientName = new ForceClientName(vd.name.name, vd.parent);
      } else if (ice.parent is AssignmentExpression) {
        AssignmentExpression expression = ice.parent;

        if (expression.leftHandSide is SimpleIdentifier) {
          SimpleIdentifier si = expression.leftHandSide;

          forceClientName = new ForceClientName(si.name, expression.parent);
        } else {
          for ( var leftHandPart in expression.leftHandSide ) {
            if (leftHandPart is SimpleIdentifier) {
              SimpleIdentifier si = leftHandPart;

              forceClientName = new ForceClientName(si.name, expression.parent);
            } else {
              print("not a simpleIdentifier found!");
              print(leftHandPart);
            }
          };
        }
      }
    }
    return forceClientName;
  }

  FunctionDeclaration _findMainMethod() {
    List<FunctionDeclaration> methods = new List<FunctionDeclaration>();
    methods.addAll(compilationUnit.declarations
    .where((m) => m is FunctionDeclaration &&
      m.name.name == "main"
    )
    // Erasing the type of the returned where iterable to allow checked-mode
    .map((cd) {
      return cd;
    }));
    if (methods.length > 0) {
      return methods[0];
    } else {
      return null;
    }
  }

  String _buildClassDefinition(ClassDeclaration receivable, forceClientName) {
    String name = receivable.name.name, defName = name.toLowerCase();

    ConstructorDeclaration constructorDeclaration =  receivable.getConstructor(null);

    FormalParameterList parameters = constructorDeclaration.parameters;
    List elements = parameters.parameters;

    var length = elements.length;
    if (length == 1) {
      // assume this is a ForceClient instance
      String fieldName = forceClientNameOfField(receivable);
      String parameterName;

      for (var el in elements) {
        if (el is FieldFormalParameter) {
          FieldFormalParameter ffp = el;
          parameterName = ffp.identifier.name;
        }
      }

      if (fieldName == parameterName) {
        return '$name $defName = new $name($forceClientName);\n';
      } else {
        print('[warning] ... could not create instance of receivable');
        return '';
      }
    }

    return '$name $defName = new $name();\n';
  }

  String forceClientNameOfField(receivable) {
    String ret_fieldName = "";

    for (ClassMember classMember in receivable.members) {
      if (classMember is FieldDeclaration) {
        FieldDeclaration fieldDeclaration = classMember;
        NodeList<VariableDeclaration> fields =
        fieldDeclaration.fields.variables;
        for (VariableDeclaration field in fields) {
          SimpleIdentifier fieldName = field.name;

          if (fieldDeclaration.toSource().indexOf('ForceClient')!=-1) {
            ret_fieldName = field.toSource();
          }
        }
      }
    }
    return ret_fieldName;
  }

  List<ForceOnProperty> _buildReceiverList(ClassDeclaration receivable) {
      List<ForceOnProperty> list = [];

      receivable.members.forEach((ClassMember member) {
        if (member is MethodDeclaration) {
          var request = "";
          MethodDeclaration md = member;
          for (var i=0;i<member.metadata.length;i++) {
            var metaData = member.metadata[i];

            if (metaData.name.name == "Receiver") {
              // metaData.childEntities
              ArgumentList argsList = metaData.arguments;
              for (var a=0;a<argsList.arguments.length;a++) {
                request = argsList.arguments[a].toString();
              }

              var methodName = md.name.name;

              list.add(new ForceOnProperty(request, methodName));
            }
          }
        }
      });

      return list;
  }

  String _buildRegisterMethod(String forceClientInstanceName, String defName, List<ForceOnProperty> fops) {
    List<String> list = [];
    for (ForceOnProperty fop in fops) {
      print( ' add ${fop.request}' );
      list.add("${forceClientInstanceName}.on(${fop.request}, ${defName}.${fop.methodName});");
    }
    return list.join("\n");
  }
}

class ForceClientName {

  String forceInstanceName;
  Expression expression;

  ForceClientName(this.forceInstanceName, this.expression);

}

class ForceOnProperty {

  String request;
  String methodName;

  ForceOnProperty(this.request, this.methodName);

}

class Editor {
  SourceFile sourceFile;
  TextEditTransaction editor;

  Editor(String path, String code) {
    sourceFile = new SourceFile(code, url: path);
    editor = new TextEditTransaction(code, sourceFile);
  }
}