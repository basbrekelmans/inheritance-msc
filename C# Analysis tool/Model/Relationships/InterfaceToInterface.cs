using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using CSharpInheritanceAnalyzer.Model.Types;

namespace CSharpInheritanceAnalyzer.Model.Relationships
{
    class InterfaceToInterface : TypeToInterface<Interface>
    {
        public InterfaceToInterface(Interface derivedType, Interface baseType) : base(derivedType, baseType)
        {
        }
        public override string InheritanceTypeName
        {
            get { return "II"; }
        }
    }
}
