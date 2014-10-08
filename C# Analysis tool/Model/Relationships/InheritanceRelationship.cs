using System;
using System.Collections.Generic;
using System.Linq;
using CSharpInheritanceAnalyzer.Model.Types;

namespace CSharpInheritanceAnalyzer.Model.Relationships
{
    public abstract class InheritanceRelationship<TDerived, TBase>
        : IInheritanceRelationship
        where TDerived : CSharpType
        where TBase : CSharpType
    {
        private readonly TBase _baseType;
        private readonly TDerived _derivedType;

        protected InheritanceRelationship(TDerived derivedType, TBase baseType)
        {
            _derivedType = derivedType;
            _baseType = baseType;
            InternalReuse = new List<Reuse>();
            ExternalReuse = new List<Reuse>();
            Downcalls = new List<Downcall>();
            Subtypes = new List<Subtype>();
        }

        public override string ToString()
        {
            return string.Format("{0} : {1}", DerivedType, BaseType);
        }

        /// <summary>
        ///     Constants interface does not exist in C#.
        ///     An edge from types E to F has the constants attribute if F has only fields
        ///     declared in it and the fields are constants (static final), and all outgoing edges
        ///     from F either have the constants attribute or are to java.lang.Object.
        ///     The type F can be either an interface or a class.
        /// </summary>
        public bool Constants
        {
            get
            {
                return BaseType.IsConstants &&
                       BaseType.BaseTypeRelationships.All(r => r.BaseType.IsObject || r.Constants);
            }
        }


        public TDerived DerivedType
        {
            get { return _derivedType; }
        }

        public TBase BaseType
        {
            get { return _baseType; }
        }

        /// <summary>
        ///     An edge from classes C (child) to D (parent) has the downcall attribute when
        ///     a method c() declared in D invokes a method m() that is declared in C.
        ///     The inheritance relationship in necessary for c() to invoke m(). The method m()
        ///     must be declared in D or an ancestor of D, so c() is making a self-call to m(), but
        ///     C overrides that declaration. The object on which the invocation takes place must
        ///     be constructed from C or one of its descendants.
        /// </summary>
        public virtual bool Downcall { get { return Downcalls.Count > 0; } }

        /// <summary>
        ///     An edge from types S (child) to T (parent) has the external reuse
        ///     attribute if there is a class E that has no inheritance relationship with T (or S), it
        ///     invokes a method m() or accesses a field f on an object declared to be of type S,
        ///     and m() or f is declared in T.
        ///     The class E is using a member of S thatwas not declared in S, which is only possible
        ///     because S has an inheritance relationship with T, so the inheritance relationship
        ///     is necessary for this to be possible. This definition does not assume S and T are
        ///     classes, but we only discuss external reuse with respect to classes in this paper.
        /// </summary>
        public IList<Reuse> ExternalReuse { get; private set; }

        public IList<Downcall> Downcalls { get; private set; }

        /// <summary>
        ///     An edge from classes A (child) to B (parent) has the internal reuse
        ///     attribute when a method declared in A invokes a method m() or accesses a field f
        ///     on an object constructed from A and m() or f is declared in B.
        ///     Without the stated inheritance relationship, it would not be possible to invoke m()
        ///     or access f in this way.
        /// </summary>
        public IList<Reuse> InternalReuse { get; private set; }

        /// <summary>
        ///     An edge from types S (child) to T (parent) has the subtype attribute when
        ///     there is a class E (which could be S or T) in which an object of type S is supplied
        ///     where an object of type T is expected. Within E, this might be assigning an object
        ///     of type S to a variable declared to be type T, passing an actual parameter of type
        ///     S to a formal parameter of type T, returning an object of type S when the formal
        ///     return type is T, or casting an expression of type S to type T.
        ///     Without the stated inheritance relationship, S would not be a subtype of T, and so
        ///     the substitutionwould not be possible. Thismeans that this relationship is necessary
        ///     for the correct behaviour of the code.
        /// </summary>
        public  IList<Subtype> Subtypes { get; private set; }


        /// <summary>
        ///     Framework: An edge from types P to Q that does not have external reuse, internal
        ///     reuse, subtype, or downcall, has the framework attribute if Q is a descendant of a
        ///     third-party type. (See also Section 4.3.)
        /// </summary>
        public virtual bool Framework
        {
            get { return !(ExternalReuse.Count >0 || InternalReuse.Count > 0 || Downcall || Subtypes.Count > 0) && !BaseType.IsOwnCode; }
        }

        /// <summary>
        ///     An edge from class K to class L has the super attribute if a constructor for K
        ///     explicitly invokes a constructor in L via super. (See also Section 4.2.)
        /// </summary>
        public bool Super { get; set; }

        /// <summary>
        ///     An edge from type R to type S has the generic attribute if there has been a
        ///     cast from Object to S and there is an edge from R to some (non-Object) type
        ///     T. (See also Section 4.3.)
        /// </summary>
        public virtual bool Generic 
        { 
            get
            {
                return BaseType.HasBeenCastFromObject && DerivedType.HasSubtypeToObject && DerivedType.BaseTypeRelationships.Any(r => r != this && !r.BaseType.IsObject);
            } 
        }

        CSharpType IInheritanceRelationship.BaseType
        {
            get { return BaseType; }
        }

        CSharpType IInheritanceRelationship.DerivedType
        {
            get { return DerivedType; }
        }

        /// <summary>
        ///     An edge from type G to interface H has the marker attribute if H has nothing
        ///     declared in it, and all outgoing edges from H have the marker attribute.
        /// </summary>
        public virtual bool Marker { get { return false; } }

        public abstract string InheritanceTypeName { get; }
    }
}