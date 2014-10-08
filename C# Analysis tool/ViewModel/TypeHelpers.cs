using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using ICSharpCode.NRefactory.TypeSystem;

namespace CSharpInheritanceAnalyzer.ViewModel
{
    static class TypeHelpers
    {
        public static string GetFullName(this IType type)
        {
            string result;

            if (type.DeclaringType != null)
            {
                result = GetFullName(type.DeclaringType) + "." + type.Name + (type.TypeParameterCount == 0 ? string.Empty : string.Format("[{0}]", type.TypeParameterCount));
            }
            else
            {
                result = type.FullName + (type.TypeParameterCount == 0 ? string.Empty : string.Format("[{0}]", type.TypeParameterCount));
            }
            return result;
        }
    }
}
