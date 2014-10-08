using System.IO;
using System.Linq;
using ICSharpCode.NRefactory.CSharp;
using ICSharpCode.NRefactory.CSharp.Resolver;
using ICSharpCode.NRefactory.CSharp.TypeSystem;

namespace CSharpInheritanceAnalyzer.ViewModel
{
    public class CSharpFile
    {
        private readonly string _filePath;
        private readonly CSharpProject _project;
        private readonly SyntaxTree _syntaxTree;
        private readonly CSharpUnresolvedFile _unresolvedTypeSystem;
        private readonly bool _exists;

        public bool FileExists
        {
            get { return _exists; }
        }

        public CSharpFile(CSharpProject project, string filePath)
        {
            _project = project;
            _filePath = filePath;

            var parser = new CSharpParser(project.CompilerSettings);
            if (!(_exists = File.Exists(filePath))) return;
            using (FileStream stream = File.OpenRead(filePath))
            {
                _syntaxTree = parser.Parse(stream, filePath);
                _unresolvedTypeSystem = _syntaxTree.ToTypeSystem();
            }
            if (parser.HasErrors)
                _project.AddToErrorCount(parser.Errors.Count());

            if (parser.HasWarnings)
                _project.AddToWarningCount(parser.Warnings.Count());
        }

        public CSharpUnresolvedFile UnresolvedTypeSystem
        {
            get { return _unresolvedTypeSystem; }
        }

        public string FilePath
        {
            get { return _filePath; }
        }

        public CSharpAstResolver CreateResolver()
        {
            return new CSharpAstResolver(_project.Compilation, _syntaxTree, _unresolvedTypeSystem);
        }

        public void AcceptAstVisitor(IAstVisitor analyzer)
        {
            _syntaxTree.AcceptVisitor(analyzer);
        }
    }
}