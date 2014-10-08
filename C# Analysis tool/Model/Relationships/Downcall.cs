using CSharpInheritanceAnalyzer.Model.Types;

namespace CSharpInheritanceAnalyzer.Model.Relationships
{
    public class Downcall
    {
        private readonly CSharpType _parentType;
        private readonly CSharpType _childType;
        private readonly Method _method;
        private readonly string _fromReference;

        public Downcall(CSharpType parentType, CSharpType childType, Method method, string fromReference)
        {
            _parentType = parentType;
            _childType = childType;
            _method = method;
            _fromReference = fromReference;
        }

        public string FromReference
        {
            get { return _fromReference; }
        }

        public Method Method
        {
            get { return _method; }
        }

        public CSharpType ChildType
        {
            get { return _childType; }
        }

        public CSharpType ParentType
        {
            get { return _parentType; }
        }
    }
}