using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace CSharpInheritanceAnalyzer.Model.Types
{
    class UnknownType : Interface
    {
        public UnknownType()
            : base(false, "UnknownType", true, 0, true)
        {
        }
    }
}
