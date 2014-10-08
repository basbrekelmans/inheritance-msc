using CSharpInheritanceAnalyzer.Model.Types;

namespace CSharpInheritanceAnalyzer.Model.Relationships
{
    public class Reuse
    {
        private readonly bool _isDirect;
        private readonly ReuseType _type;
        private readonly string _name;
        private readonly Class _fromClass;
        private readonly string _fromReference;

        public Reuse(bool isDirect, ReuseType type, string name, Class fromClass, string fromReference)
        {
            _isDirect = isDirect;
            _type = type;
            _name = name;
            _fromClass = fromClass;
            _fromReference = fromReference;
        }

        public ReuseType Type
        {
            get { return _type; }
        }

        public string Name
        {
            get { return _name; }
        }

        public string From
        {
            get { return _fromClass.GetLocString() + "/" + _fromReference; }
        }

        public bool IsDirect
        {
            get { return _isDirect; }
        }
    }
}