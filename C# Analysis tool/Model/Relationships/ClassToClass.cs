using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using CSharpInheritanceAnalyzer.Model.Types;

namespace CSharpInheritanceAnalyzer.Model.Relationships
{
    class ClassToClass : InheritanceRelationship<Class, Class>
    {
        public ClassToClass(Class derivedType, Class baseType) : base(derivedType, baseType)
        {
        }
        /// <summary>
        ///     An edge from classes C (child) to D (parent) has the downcall attribute when
        ///     a method c() declared in D invokes a method m() that is declared in C.
        ///     The inheritance relationship in necessary for c() to invoke m(). The method m()
        ///     must be declared in D or an ancestor of D, so c() is making a self-call to m(), but
        ///     C overrides that declaration. The object on which the invocation takes place must
        ///     be constructed from C or one of its descendants.
        /// </summary>
        public override bool Downcall
        {
            get 
            { 
                //methods called in base type that are declared in derived type
                return (from calledMethod in BaseType.CalledMethods.Intersect(DerivedType.DeclaredMethods) 
                          select calledMethod ).Any(); 
            }
        }

        public override bool Marker
        {
            get { return false; }
        }

        public override string InheritanceTypeName
        {
            get { return "CC"; }
        }
    }
}
