using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace CSharpInheritanceAnalyzer.Model.Relationships
{
    public class Subtype
    {
        private readonly bool _isDirect;
        private readonly SubtypeKind _kind;
        private readonly string _fromReference;

        public Subtype(bool isDirect, SubtypeKind kind, string fromReference)
        {
            _isDirect = isDirect;
            _kind = kind;
            _fromReference = fromReference;
        }

        public string FromReference
        {
            get { return _fromReference; }
        }

        public SubtypeKind Kind
        {
            get { return _kind; }
        }

        public bool IsDirect
        {
            get { return _isDirect; }
        }
    }
}
