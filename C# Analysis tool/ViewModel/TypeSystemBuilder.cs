using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using System.Reflection;
using CSharpInheritanceAnalyzer.Model.Relationships;
using CSharpInheritanceAnalyzer.Model.Types;
using ICSharpCode.NRefactory.CSharp;
using ICSharpCode.NRefactory.CSharp.Resolver;
using ICSharpCode.NRefactory.Semantics;
using ICSharpCode.NRefactory.TypeSystem;
using ICSharpCode.NRefactory.TypeSystem.Implementation;

namespace CSharpInheritanceAnalyzer.ViewModel
{
    public class TypeSystemBuilder : VisitorBase
    {
        private static readonly FieldInfo GenericTypeField = typeof (ParameterizedType).GetField("genericType",
            BindingFlags.Instance | BindingFlags.NonPublic);

        public TypeSystemBuilder(CSharpAstResolver resolver, IDictionary<string, CSharpType> types,
            List<IInheritanceRelationship> edges, HashSet<string> ownCodeAssemblyNames)
            : base(resolver, types, edges, ownCodeAssemblyNames)
        {
            if (!types.ContainsKey("System.Object"))
            {
                types.Add("System.Object", new Class(false, "System.Object", false, 0, false));
            }
        }

        public override void VisitTypeDeclaration(TypeDeclaration typeDeclaration)
        {
            //ignore enums
            if (typeDeclaration.ClassType == ClassType.Enum)
                return;

            ResolveResult result = Resolver.Resolve(typeDeclaration);

            if (result is ErrorResolveResult)
            {
                Trace.WriteLine("Error resolving " + typeDeclaration.Name);
                return;
            }
            var members = result.Type.GetMembers().Where(m => m.DeclaringType.FullName != "System.Object").ToList();
            bool constants = members.Count > 0 &&  members.All(member => member.SymbolKind == SymbolKind.Field 
                                                && member.IsStatic 
                                                && ((IField) member).IsReadOnly);

            bool marker = members.Count == 0;

            string fullyQualifiedTypeName = result.Type.GetFullName();

            CSharpType type;
            if (!Types.TryGetValue(fullyQualifiedTypeName, out type))
            {
                type = CreateType(fullyQualifiedTypeName, typeDeclaration.ClassType, true, constants, typeDeclaration.TypeParameters.Count, marker);
                Types.Add(result.Type.GetFullName(), type);
            }

            foreach (AstType baseType in typeDeclaration.BaseTypes)
            {
                ResolveResult resolveResult = Resolver.Resolve(baseType);
                CSharpType baseTypeDefinition;
                if (!Types.TryGetValue(resolveResult.Type.GetFullName(), out baseTypeDefinition))
                {
                    var resolvedType = resolveResult.Type as DefaultResolvedTypeDefinition;
                    if (resolvedType == null)
                    {
                        var parametrizedType = resolveResult.Type as ParameterizedType;
                        if (parametrizedType == null)
                        {
                            Debug.WriteLine("Unknown type: " + baseType);
                            continue;
                        }
                        resolvedType = GetGenericType(parametrizedType);
                        if (Types.TryGetValue(resolvedType.GetFullName(), out baseTypeDefinition))
                        {
                            //open generic has been matched;
                        }
                    }
                    if (baseTypeDefinition == null)
                    {
                        var baseMembers = resolvedType.GetMembers().Where(m => m.DeclaringType.FullName != "System.Object").ToList();
                        bool baseConstants = baseMembers.Count > 0 && baseMembers.All(member => member.SymbolKind == SymbolKind.Field
                                                            && member.IsStatic
                                                            && ((IField)member).IsReadOnly);

                        bool baseMarker = baseMembers.Count == 0;
                        bool isOwnCode = OwnCodeAssemblyNames.Contains(resolvedType.ParentAssembly.AssemblyName);
                        ClassType classType = GetClassType(resolvedType);
                        baseTypeDefinition = CreateType(resolvedType.GetFullName(), classType, isOwnCode, baseConstants, resolvedType.TypeParameterCount, baseMarker);
                        Types.Add(baseTypeDefinition.FullyQualifiedName, baseTypeDefinition);
                        if (!isOwnCode)
                        {
                            foreach (var member in resolvedType.Members.OfType<IParameterizedMember>())
                            {
                                var returnType = GetTypeOrCreateExternal(member.ReturnType);
                                var parameters = member.Parameters.Select(p => GetTypeOrCreateExternal(p.Type)).ToArray();

                                baseTypeDefinition.DeclaredMethods.Add(new Method(baseTypeDefinition, member.Name, returnType, parameters));
                            }
                        }
                    }
                }
                if (type.BaseTypeRelationships.All(r => r.BaseType != baseTypeDefinition))
                {
                    IInheritanceRelationship relation = type.AddBaseType(baseTypeDefinition);
                    Edges.Add(relation);
                }
            }
            if (type is Class && type.BaseTypeRelationships.All(b => !(b is Class)))
            {
                type.AddBaseType(Types["System.Object"]);
            }

            foreach (var astNode in typeDeclaration.Children)
            {
                astNode.AcceptVisitor(this);
            }
        }
        
        private DefaultResolvedTypeDefinition GetGenericType(ParameterizedType parametrizedType)
        {
            return GenericTypeField.GetValue(parametrizedType) as DefaultResolvedTypeDefinition;
        }

        protected static ClassType GetClassType(DefaultResolvedTypeDefinition resolvedType)
        {
            switch (resolvedType.Kind)
            {
                case TypeKind.Class:
                    return ClassType.Class;
                case TypeKind.Interface:
                    return ClassType.Interface;
                default:
                    throw new ArgumentOutOfRangeException();
            }
        }

        protected CSharpType CreateType(string fullyQualifiedTypeName, ClassType classType, bool isOwnCode, bool constants, int parameterCount, bool marker)
        {
            switch (classType)
            {
                case ClassType.Class:
                case ClassType.Struct:
                    return new Class(isOwnCode, fullyQualifiedTypeName, constants, parameterCount,marker);
                case ClassType.Interface:
                    return new Interface(isOwnCode, fullyQualifiedTypeName, constants, parameterCount, marker);
                default:
                    throw new ArgumentOutOfRangeException("classType");
            }
        }
    }
}