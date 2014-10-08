using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using CSharpInheritanceAnalyzer.Model.Relationships;
using CSharpInheritanceAnalyzer.Model.Types;
using ICSharpCode.NRefactory.CSharp;
using ICSharpCode.NRefactory.CSharp.Resolver;
using ICSharpCode.NRefactory.Semantics;
using ICSharpCode.NRefactory.TypeSystem;
using ICSharpCode.NRefactory.TypeSystem.Implementation;

namespace CSharpInheritanceAnalyzer.ViewModel
{
    internal class MethodDeclarationVisitor : VisitorBase
    {
        public MethodDeclarationVisitor(CSharpAstResolver resolver, IDictionary<string, CSharpType> types,
            List<IInheritanceRelationship> edges, HashSet<string> ownCodeAssemblyNames)
            : base(resolver, types, edges, ownCodeAssemblyNames)
        {
        }

        public override void VisitPropertyDeclaration(PropertyDeclaration propertyDeclaration)
        {
            ResolveResult resolveResult = Resolver.Resolve(propertyDeclaration);
            if (resolveResult is ErrorResolveResult)
            {
                Trace.WriteLine("Error resolving property: " + propertyDeclaration.ToString());
                return;
            }
            IMember member = ((MemberResolveResult) resolveResult).Member;
            CSharpType declaringType = Types[member.DeclaringType.GetFullName()];
            CSharpType returnType = GetTypeOrCreateExternal(member.ReturnType);
            if (!propertyDeclaration.Getter.IsNull)
            {
                var getterMethod = new Method(declaringType, propertyDeclaration.Name, returnType);
                AddMethod(declaringType, getterMethod);
            }
            if (!propertyDeclaration.Setter.IsNull)
            {
                var setterMethod = new Method(declaringType, propertyDeclaration.Name, CSharpType.Unknown,
                    new[] {declaringType });
                AddMethod(declaringType, setterMethod);
            }
        }

        public override void VisitConstructorInitializer(ConstructorInitializer constructorInitializer)
        {
            if (constructorInitializer.ConstructorInitializerType == ConstructorInitializerType.Base)
            {
                //super attribute
                //we know: base type already exists in system. So we can get the 
                //current type declaration and find the base class
                //then assign the 'super' attribute to the relation
                var declaration = constructorInitializer.GetParent<TypeDeclaration>();

                ResolveResult resolveResult = Resolver.Resolve(declaration);
                //type should exist here
                var relationship =
                    Types[resolveResult.Type.GetFullName()].BaseTypeRelationships.OfType<ClassToClass>()
                        .FirstOrDefault();
                if (relationship != null)
                {
                    relationship.Super = true;
                }
                else
                {
                    Trace.WriteLine("Base Type of super invocation was not found for type" +
                                    resolveResult.Type.GetFullName());
                }
                
            }
        }

        public override void VisitMethodDeclaration(MethodDeclaration methodDeclaration)
        {
            ResolveResult result = Resolver.Resolve(methodDeclaration);
            if (!result.IsError)
            {
                var defaultResult = result as MemberResolveResult;
                var member = defaultResult.Member as DefaultResolvedMethod;
                CSharpType declaringType = Types[member.DeclaringType.GetFullName()];
                CSharpType returnType = GetTypeOrCreateExternal(member.ReturnType);
                CSharpType[] parameters = member.Parameters.Select(t => GetTypeOrCreateExternal(t.Type)).ToArray();
                var method = new Method(declaringType, member.Name, returnType, parameters);
                foreach (IMember implementedInterfaceMember in member.ImplementedInterfaceMembers)
                {
                    CSharpType interfaceType = GetTypeOrCreateExternal(implementedInterfaceMember.DeclaringType);
                    interfaceType.OverrideOccurrences.Add(method);
                }
                AddMethod(declaringType, method);    
            }
            else if (result.IsError && methodDeclaration.TypeParameters.Count > 0)
            {
                //this is a method using only Type parameters in its usage.
            }
            
        }
        
        private void AddMethod(CSharpType declaringType, Method method)
        {
            declaringType.DeclaredMethods.Add(method);
        }
    }
}