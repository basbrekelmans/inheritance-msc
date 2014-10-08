using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows;
using CSharpInheritanceAnalyzer.Model.Relationships;
using CSharpInheritanceAnalyzer.Model.Types;
using ICSharpCode.NRefactory.CSharp;
using ICSharpCode.NRefactory.CSharp.Resolver;
using ICSharpCode.NRefactory.Semantics;
using ICSharpCode.NRefactory.TypeSystem;
using Expression = ICSharpCode.NRefactory.CSharp.Expression;

namespace CSharpInheritanceAnalyzer.ViewModel
{
public class CallVisitor : VisitorBase
    {
        public CallVisitor(CSharpAstResolver resolver, IDictionary<string, CSharpType> types, List<IInheritanceRelationship> edges, HashSet<string> ownCodeAssemblyNames) : base(resolver, types, edges, ownCodeAssemblyNames)
        {
        }

        public override void VisitConditionalExpression(ConditionalExpression conditionalExpression)
        {
            base.VisitConditionalExpression(conditionalExpression);
            var left = conditionalExpression.TrueExpression;
            var right = conditionalExpression.FalseExpression;

            var leftResolve = Resolver.Resolve(left);
            var rightResolve = Resolver.Resolve(right);

            if (leftResolve.IsError || rightResolve.IsError) return;
            CreateSubtypeRelation(conditionalExpression, rightResolve.Type, leftResolve.Type, SubtypeKind.Assignment, right is ThisReferenceExpression);
            CreateSubtypeRelation(conditionalExpression, leftResolve.Type, rightResolve.Type, SubtypeKind.Assignment, left is ThisReferenceExpression);
        }

        public override void VisitInvocationExpression(ICSharpCode.NRefactory.CSharp.InvocationExpression invocationExpression)
        {
            base.VisitInvocationExpression(invocationExpression);
            var result = Resolver.Resolve(invocationExpression) as InvocationResolveResult;
            if (result == null)
            {
                Trace.WriteLine(String.Format("Unknown invocation resolution at {0}", invocationExpression));
                return;
            }
            var methodDeclaringType = GetTypeOrCreateExternal(result.Member.DeclaringType);
            CheckCallForSubtype(invocationExpression.Arguments, result.Member);

            var targetDeclaringType = GetTypeOrCreateExternal(result.TargetResult.Type);
            var currentDeclaringTypeResolve = Resolver.Resolve(invocationExpression.GetParent<TypeDeclaration>());
            if (currentDeclaringTypeResolve.IsError) return;
            var currentMethod = invocationExpression.GetParent<MethodDeclaration>();
            string fromReference = currentMethod == null ? "(field initializer)" : currentMethod.Name;
            var currentDeclaringType = (Class)GetTypeOrCreateExternal(currentDeclaringTypeResolve.Type);
            if (currentDeclaringType.IsChildOf(methodDeclaringType))
            {
                var items = currentDeclaringType.GetPathTo(methodDeclaringType);
                bool direct = currentDeclaringType.IsDirectChildOf(methodDeclaringType);
                foreach (var item in items)
                {
                    item.InternalReuse.Add(new Reuse(direct, ReuseType.MethodCall, result.Member.Name,
                    currentDeclaringType, fromReference));
            }
            }
            else if (targetDeclaringType.IsChildOf(methodDeclaringType))
            {
                var items = targetDeclaringType.GetPathTo(methodDeclaringType);
                bool direct = targetDeclaringType.IsDirectChildOf(methodDeclaringType);
                foreach (var item in items)
                {
                    item.InternalReuse.Add(new Reuse(direct, ReuseType.MethodCall, result.Member.Name,
                    currentDeclaringType, fromReference));
            }
            }

            if (result.IsVirtualCall && (currentDeclaringType == methodDeclaringType || currentDeclaringType.IsChildOf(methodDeclaringType)))
            {
                var method = CreateMethod(result.Member);
                //maybe a downcall somewhere
                foreach (var downcallCandidate in methodDeclaringType.AllDerivedTypes().Where(t => t.DeclaredMethods.Contains(method)))
                {
                    var relation = downcallCandidate.GetImmediateParent(methodDeclaringType);
                    relation.Downcalls.Add(
                        new Downcall(relation.BaseType, relation.DerivedType, method, fromReference));
                }
            }
        }

        private void CheckCallForSubtype(IEnumerable<Expression> args, IParameterizedMember member)
        {
            var paramsEnumerator = EnumerateParameters(member).GetEnumerator();
            var argumentsEnumerator = args.GetEnumerator();

            while (argumentsEnumerator.MoveNext() & paramsEnumerator.MoveNext())
            {
                var argument = argumentsEnumerator.Current;
                var parameter = paramsEnumerator.Current;
                var argumentResolve = Resolver.Resolve(argument);
                CreateSubtypeRelation(argument, argumentResolve.Type, parameter.Type, SubtypeKind.Parameter, argument is ThisReferenceExpression);
            }
        }

        private IEnumerable<IParameter> EnumerateParameters(IParameterizedMember member)
        {
            bool isParams = false;
            int i = 0;
            while (i < member.Parameters.Count || isParams)
            {
                
                yield return member.Parameters[i];
                isParams |= member.Parameters[i].IsParams;
                if (!isParams)
                    ++i;
            }
        }

        public override void VisitObjectCreateExpression(ObjectCreateExpression objectCreateExpression)
        {
            base.VisitObjectCreateExpression(objectCreateExpression);
            //constructor call, can never be internal/external reuse
            var resolve = Resolver.Resolve(objectCreateExpression);

            if (resolve.IsError)
            {
                Trace.WriteLine("Could not resolve constructor: " + objectCreateExpression);
                return;
            }

            if (resolve is ConversionResolveResult)
            {
                //found an occurrance of "new Action(MyMethod)" pattern
                //don't care about those
                return;
            }

            if (resolve is DynamicInvocationResolveResult)
            {
                //cannot do something with dynamic invocation
                return;
            }

            CheckCallForSubtype(objectCreateExpression.Arguments, ((InvocationResolveResult)resolve).Member);

            var test = resolve.Type;

        }

        public override void VisitVariableInitializer(VariableInitializer variableInitializer)
        {
            base.VisitVariableInitializer(variableInitializer);
            IType leftType = null;
            var result = Resolver.Resolve(variableInitializer);
            if (result.IsError)
            {
                Trace.WriteLine("Error resolving: " + variableInitializer);
                return;
            }
            var memberResult = result as MemberResolveResult;
            if (memberResult != null)
            {
                leftType = memberResult.Member.ReturnType;
            }
            else
            {
                var localResult = result as LocalResolveResult;
                if (localResult != null)
                {
                    leftType = localResult.Variable.Type;
                }
                else
                {
                    Debugger.Break();
                }
            }
            var initializerResolve = Resolver.Resolve(variableInitializer.Initializer);

            CreateSubtypeRelation(variableInitializer, initializerResolve.Type, leftType, SubtypeKind.VariableInitializer, variableInitializer.Initializer is ThisReferenceExpression);
        }

        public override void VisitCastExpression(CastExpression castExpression)
        {
            base.VisitCastExpression(castExpression);

            var targetTypeResolve = Resolver.Resolve(castExpression);
            var fromTypeResolve = Resolver.Resolve(castExpression.Expression);
            var leftType = GetTypeOrCreateExternal(targetTypeResolve.Type);
            var rightType = GetTypeOrCreateExternal(fromTypeResolve.Type);
            if (rightType.IsObject)
            {
                leftType.HasBeenCastFromObject = true;
            }
            CreateSubtypeRelation(castExpression, targetTypeResolve.Type, fromTypeResolve.Type, SubtypeKind.Cast, castExpression.Expression is ThisReferenceExpression);
            CreateSubtypeRelation(castExpression, fromTypeResolve.Type, targetTypeResolve.Type, SubtypeKind.Cast, castExpression.Expression is ThisReferenceExpression);
        }

        public override void VisitReturnStatement(ReturnStatement returnStatement)
        {
            base.VisitReturnStatement(returnStatement);
            var expr = returnStatement.Expression;
            var exprResolve = Resolver.Resolve(expr);
            var exprType = GetTypeOrCreateExternal(exprResolve.Type);
            var returnType = TryGetReturnType(returnStatement);
            if (returnType != null)
            {
                CreateSubtypeRelation(returnStatement, exprResolve.Type, returnType, SubtypeKind.Return, returnStatement.Expression is ThisReferenceExpression);    
            }
        }

        private IType TryGetReturnType(AstNode node)
        {
            IType resolvedType = null;
            resolvedType = TryGetEntityDeclarationReturnType(node);
            if (resolvedType == null)
            {
                var anonymousMethodExpression = node.GetParent<AnonymousMethodExpression>();
                if (anonymousMethodExpression == null) return null;
                var parent = anonymousMethodExpression.Parent;
                if (parent is AssignmentExpression)
                {
                    resolvedType = Resolver.Resolve(((AssignmentExpression)parent).Left).Type;
                }
                else if (parent is VariableInitializer)
                {
                    resolvedType = Resolver.Resolve(((VariableDeclarationStatement)parent.Parent).Type).Type;
                }
                else
                {
                    // TODO: handle invocations
                    throw new Exception();
                }

            }
            return resolvedType;
        }

        private IType TryGetEntityDeclarationReturnType(AstNode node)
        {
            var method = node.GetParent<EntityDeclaration>();
            if (method != null)
            {
                var resolve = Resolver.Resolve(method);
                if (!resolve.IsError)
                    return resolve.Type;
            }
            return null;
        }

        public override void VisitAsExpression(AsExpression asExpression)
        {
            base.VisitAsExpression(asExpression);

            var targetTypeResolve = Resolver.Resolve(asExpression);
            var fromTypeResolve = Resolver.Resolve(asExpression.Expression);
            var rightType = GetTypeOrCreateExternal(fromTypeResolve.Type);
            var leftType = GetTypeOrCreateExternal(targetTypeResolve.Type);
            if (rightType.IsObject)
            {
                leftType.HasBeenCastFromObject = true;
            }
            CreateSubtypeRelation(asExpression, fromTypeResolve.Type, targetTypeResolve.Type, SubtypeKind.Cast, asExpression.Expression is ThisReferenceExpression);
            CreateSubtypeRelation(asExpression, targetTypeResolve.Type, fromTypeResolve.Type, SubtypeKind.Cast, asExpression.Expression is ThisReferenceExpression);
        }

        public override void VisitAssignmentExpression(AssignmentExpression assignmentExpression)
        {
            base.VisitAssignmentExpression(assignmentExpression);
            //subtype occurs if left type is a base class of right type
            var resolveLeft = Resolver.Resolve(assignmentExpression.Left);
            var resolveRight = Resolver.Resolve(assignmentExpression.Right);
            CreateSubtypeRelation(assignmentExpression, resolveRight.Type, resolveLeft.Type, SubtypeKind.Assignment, assignmentExpression.Right is ThisReferenceExpression);
        }

        private void CreateSubtypeRelation(AstNode node,
            IType right, IType left, SubtypeKind kind, bool isRightTypeThis)
        {
            var leftType = GetTypeOrCreateExternal(left);
            var rightType = GetTypeOrCreateExternal(right);

            var currentMethod = node.GetParent<MethodDeclaration>() ??
                                node.GetParent<ConstructorDeclaration>() as EntityDeclaration ?? 
                                node.GetParent<PropertyDeclaration>();
            string fromReference = currentMethod == null ? "(field initializer)" : currentMethod.Name;
            var currentDeclaringTypeResolve = Resolver.Resolve(node.GetParent<TypeDeclaration>());
            fromReference += " in " + currentDeclaringTypeResolve.Type.FullName;

            //left is the parent, right is the child
            for (int i = 0; i < left.TypeArguments.Count && i < right.TypeArguments.Count; i++)
            {
                var leftArg = left.TypeArguments[i];
                var rightArg = right.TypeArguments[i];
                var leftArgument = GetTypeOrCreateExternal(leftArg);
                var rightArgument = GetTypeOrCreateExternal(rightArg);
                CreateSubtypeRelation(node, leftArg, rightArg, SubtypeKind.CovariantTypeArgument, false);
                CreateSubtypeRelation(node, rightArg, leftArg, SubtypeKind.ContravariantTypeArgument, false);
            }


            if (rightType.IsChildOf(leftType))
            {
                rightType.HasSubtypeToObject |= leftType.IsObject;
                var relations = rightType.GetPathTo(leftType);
                foreach (var item in relations)
                {
                    item.Subtypes.Add(new Subtype(item.BaseType == leftType && item.DerivedType == rightType, kind,
                    fromReference));
            }
            }
            if (isRightTypeThis && kind == SubtypeKind.Parameter)
            {
                foreach (var derivedType in rightType.AllDerivedTypes())
                {
                    var relation = derivedType.GetImmediateParent(rightType);
                    relation.Subtypes.Add(new Subtype(derivedType.IsDirectChildOf(rightType),
                        SubtypeKind.ThisChangingType, fromReference));

                }
            }
        }

        public override void VisitIdentifierExpression(IdentifierExpression identifier)
        {
            base.VisitIdentifierExpression(identifier);
            //prevent duplicate entries from member reference
            if (identifier.GetParent<MemberReferenceExpression>() != null) return;
            var resolveResult = Resolver.Resolve(identifier);
            var memberResolve = resolveResult as MemberResolveResult;
            //variable access without this qualifier
            if (memberResolve != null && memberResolve.Member.DeclaringType.Kind != TypeKind.Enum)
            {
                var targetType = GetTypeOrCreateExternal(memberResolve.Member.DeclaringType);
                var currentDeclaringTypeResolve = Resolver.Resolve(identifier.GetParent<TypeDeclaration>());
                //it is possible that we are inside an enumeration, inside a nested type, referencing an identifier
                //defined in the outer type. In that case, we want to use the outer type as the source
                //22-9: fixed refernce to boolean constant defined in outer type
                if (currentDeclaringTypeResolve.Type.Kind == TypeKind.Enum 
                    || currentDeclaringTypeResolve.Type.Kind == TypeKind.Interface
                    || currentDeclaringTypeResolve.Type.Kind == TypeKind.Delegate) 
                {
                    currentDeclaringTypeResolve =
                        Resolver.Resolve(identifier.GetParent<TypeDeclaration>().GetParent<TypeDeclaration>());
                }

                string currentReferenceName = identifier.GetParent<MethodDeclaration>() == null
                    ? "(field initializer)"
                    : identifier.GetParent<MethodDeclaration>().Name;
                var currentDeclaringType = (Class)GetTypeOrCreateExternal(currentDeclaringTypeResolve.Type);
                bool possibleUpCall = currentDeclaringType.IsChildOf(targetType);
                if (possibleUpCall)
                {
                    bool direct = currentDeclaringType.IsDirectChildOf(targetType);
                    foreach (var item in currentDeclaringType.GetPathTo(targetType))
                    {
                        item.InternalReuse.Add(new Reuse(direct, ReuseType.FieldAccess, memberResolve.Member.Name, currentDeclaringType, currentReferenceName));   
                }
                }
                
            }

        }

        public override void VisitMemberReferenceExpression(ICSharpCode.NRefactory.CSharp.MemberReferenceExpression memberReferenceExpression)
        {
            OnVisitMemberReference(memberReferenceExpression);
            foreach (var astNode in memberReferenceExpression.Children)
            {
                astNode.AcceptVisitor(this);
            }
        }

        public override void VisitForeachStatement(ForeachStatement foreachStatement)
        {
            base.VisitForeachStatement(foreachStatement);
            var variableType = foreachStatement.VariableType;
            var variableTypeResolve = Resolver.Resolve(variableType).Type;
            var enumerableResolution = Resolver.Resolve(foreachStatement.InExpression);
            if (enumerableResolution.IsError) return;

            var enumerableInterfaceBase = enumerableResolution.Type.GetAllBaseTypes().OfType<ParameterizedType>()
                .Where(t => t.Kind == TypeKind.Interface && t.FullName == "System.Collections.Generic.IEnumerable")
                .FirstOrDefault();
            IType elementType;
            if (enumerableInterfaceBase != null)
            {
                elementType = enumerableInterfaceBase.TypeArguments[0];

            }
            else if (enumerableResolution.Type.Kind == TypeKind.Array) 
            {
                elementType = ((ArrayType)enumerableResolution.Type).ElementType;
            }
            else if (enumerableResolution.Type.Kind == TypeKind.Dynamic)
            {
                DynamicUsage++;
                return;
            }
            else if (enumerableResolution.Type.Kind == TypeKind.Unknown)
            {
                //unbound generic or unknown element type;
                return;
            }
            else
            {
                var nonGenericEnumerableBase = enumerableResolution.Type.GetAllBaseTypes()
                    .FirstOrDefault(b => b.Kind == TypeKind.Interface && b.FullName == "System.Collections.IEnumerable");
                if (nonGenericEnumerableBase != null)
                {
                    elementType = nonGenericEnumerableBase.GetAllBaseTypes().Where(t => t.FullName == "System.Object").FirstOrDefault();
                }      
                else 
                {
                    //corner case: Only implements GetEnumerator()
                    var method = enumerableResolution.Type.GetMethods().Where(m => m.Name == "GetEnumerator" && m.Parameters.Count == 0).FirstOrDefault();
                    IProperty property;
                    if (method != null && (property = method.ReturnType.GetProperties().Where(p => p.Name == "Current" && p.CanGet).FirstOrDefault()) != null)
                    {
                        elementType = property.ReturnType;
                    }
                    else
                    {
                        Trace.WriteLine("Unresolved foreach statement at " + foreachStatement);
                        return;

                    }
                }
            }
            CreateSubtypeRelation(foreachStatement, elementType, variableTypeResolve, SubtypeKind.Foreach, foreachStatement.InExpression is ThisReferenceExpression);
            CreateSubtypeRelation(foreachStatement, variableTypeResolve, elementType, SubtypeKind.Foreach, foreachStatement.InExpression is ThisReferenceExpression);
        }

        private void OnVisitMemberReference(MemberReferenceExpression memberReferenceExpression)
        {
            var resolveResult = Resolver.Resolve(memberReferenceExpression);
            var methodGroupResolve = resolveResult as MethodGroupResolveResult;
            var memberResolve = resolveResult as MemberResolveResult;
            if (methodGroupResolve != null)
            {
                //handled by invocation
            }
            else if (memberResolve != null)
            {
                var memberDeclaringType = GetTypeOrCreateExternal(memberResolve.Member.DeclaringType);
                var target = memberResolve.TargetResult;
                var currentTypeResolve = Resolver.Resolve(memberReferenceExpression.GetParent<TypeDeclaration>());
                if (currentTypeResolve.IsError) return;
                string currentReferenceName = memberReferenceExpression.GetParent<MethodDeclaration>() == null
                    ? "(field initializer)"
                    : memberReferenceExpression.GetParent<MethodDeclaration>().Name;

                var currentType = GetTypeOrCreateExternal(currentTypeResolve.Type);
                var targetType = GetTypeOrCreateExternal(target.Type);
                bool possibleDownCall = currentType.IsParentOf(memberDeclaringType);
                bool possibleUpCall = currentType.IsChildOf(memberDeclaringType);
                bool externalReuse = !possibleUpCall && targetType.IsChildOf(memberDeclaringType);
                bool isDirectRelation = false;

                IEnumerable<IInheritanceRelationship> upcallRelations = null;
                IEnumerable<IInheritanceRelationship> externalReuseRelations = null;
                if (possibleUpCall)
                {
                    upcallRelations = currentType.GetPathTo(memberDeclaringType);
                    isDirectRelation = currentType.IsDirectChildOf(memberDeclaringType);
                }
                if (externalReuse)
                {
                    externalReuseRelations = targetType.GetPathTo(memberDeclaringType);
                    isDirectRelation = targetType.IsDirectChildOf(memberDeclaringType);
                }

                ReuseType reuseType;
                switch (memberResolve.Member.SymbolKind)
                {
                    case SymbolKind.Field:
                        reuseType = ReuseType.FieldAccess;
                        //downcall not possible
                        break;
                    case SymbolKind.Property:
                    case SymbolKind.Indexer:
                    case SymbolKind.Event:
                    case SymbolKind.Operator:
                    case SymbolKind.Constructor:
                        //upcall for "Super"
                    case SymbolKind.Destructor:
                        reuseType = ReuseType.MethodCall;
                        break;
                    default:
                        throw new ArgumentOutOfRangeException();
                }
                if (possibleUpCall)
                {
                    foreach (var item in upcallRelations)
                    {
                        item.InternalReuse.Add(new Reuse(isDirectRelation, reuseType,
                        memberResolve.Member.Name,
                        (Class)currentType, currentReferenceName));
                }
                }
                if (externalReuse)
                {
                    foreach (var item in externalReuseRelations)
                    {
                        item.ExternalReuse.Add(new Reuse(isDirectRelation, reuseType,
                        memberResolve.Member.Name,
                        (Class)currentType, currentReferenceName));
                    }
                }
            }
            //other cases: Type/Namespace access; not relevant for this case.
        }
    }

interface I1
interface I2

    class Child : I1, I2

    void M(I1 item)
    {
        I2 i2 = (I2)item;
    }
}
