USE [master]
GO
/****** Object:  Database [MasterThesis]    Script Date: 7-10-2014 15:00:03 ******/
CREATE DATABASE [MasterThesis]
GO
ALTER DATABASE [MasterThesis] SET COMPATIBILITY_LEVEL = 110
GO
IF (1 = FULLTEXTSERVICEPROPERTY('IsFullTextInstalled'))
begin
EXEC [MasterThesis].[dbo].[sp_fulltext_database] @action = 'enable'
end
GO
ALTER DATABASE [MasterThesis] SET ANSI_NULL_DEFAULT OFF 
GO
ALTER DATABASE [MasterThesis] SET ANSI_NULLS OFF 
GO
ALTER DATABASE [MasterThesis] SET ANSI_PADDING OFF 
GO
ALTER DATABASE [MasterThesis] SET ANSI_WARNINGS OFF 
GO
ALTER DATABASE [MasterThesis] SET ARITHABORT OFF 
GO
ALTER DATABASE [MasterThesis] SET AUTO_CLOSE OFF 
GO
ALTER DATABASE [MasterThesis] SET AUTO_CREATE_STATISTICS ON 
GO
ALTER DATABASE [MasterThesis] SET AUTO_SHRINK OFF 
GO
ALTER DATABASE [MasterThesis] SET AUTO_UPDATE_STATISTICS ON 
GO
ALTER DATABASE [MasterThesis] SET CURSOR_CLOSE_ON_COMMIT OFF 
GO
ALTER DATABASE [MasterThesis] SET CURSOR_DEFAULT  GLOBAL 
GO
ALTER DATABASE [MasterThesis] SET CONCAT_NULL_YIELDS_NULL OFF 
GO
ALTER DATABASE [MasterThesis] SET NUMERIC_ROUNDABORT OFF 
GO
ALTER DATABASE [MasterThesis] SET QUOTED_IDENTIFIER OFF 
GO
ALTER DATABASE [MasterThesis] SET RECURSIVE_TRIGGERS OFF 
GO
ALTER DATABASE [MasterThesis] SET  DISABLE_BROKER 
GO
ALTER DATABASE [MasterThesis] SET AUTO_UPDATE_STATISTICS_ASYNC OFF 
GO
ALTER DATABASE [MasterThesis] SET DATE_CORRELATION_OPTIMIZATION OFF 
GO
ALTER DATABASE [MasterThesis] SET TRUSTWORTHY OFF 
GO
ALTER DATABASE [MasterThesis] SET ALLOW_SNAPSHOT_ISOLATION OFF 
GO
ALTER DATABASE [MasterThesis] SET PARAMETERIZATION SIMPLE 
GO
ALTER DATABASE [MasterThesis] SET READ_COMMITTED_SNAPSHOT OFF 
GO
ALTER DATABASE [MasterThesis] SET HONOR_BROKER_PRIORITY OFF 
GO
ALTER DATABASE [MasterThesis] SET RECOVERY SIMPLE 
GO
ALTER DATABASE [MasterThesis] SET  MULTI_USER 
GO
ALTER DATABASE [MasterThesis] SET PAGE_VERIFY CHECKSUM  
GO
ALTER DATABASE [MasterThesis] SET DB_CHAINING OFF 
GO
ALTER DATABASE [MasterThesis] SET FILESTREAM( NON_TRANSACTED_ACCESS = OFF ) 
GO
ALTER DATABASE [MasterThesis] SET TARGET_RECOVERY_TIME = 0 SECONDS 
GO
USE [MasterThesis]
GO
/****** Object:  StoredProcedure [dbo].[CreateMergedProject]    Script Date: 7-10-2014 15:00:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[CreateMergedProject]
	@Name nvarchar(100)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	create table #ProjectIds (
		ProjectId int not null
	);

	declare @NewProjectId int;

	insert into #ProjectIds select ProjectId from Project where Name like @Name + '%';

	insert into dbo.Project 
		(Language, Name, CreatedDate, LinesOfCode, LinesOfComment, LinesOfBlank, ProjectType)
	select 
		Language, @Name, getdate(), sum(LinesOfCode), sum(LinesOfComment), sum(linesOfBlank), 'Merged'
		from dbo.Project where projectId in (select ProjectId from #ProjectIds)
		group by Language;

	set @NewProjectId = SCOPE_IDENTITY();

	insert into 
		dbo.Type (ProjectId, TypeLocation, IsOwnCode)
		select @NewProjectId, TypeLocation, MAX(CAST(IsOwnCode AS tinyint))
		from dbo.Type where projectId in (select ProjectId from #ProjectIds)
		group by TypeLocation
		
	 
	

	exec dbo.EmptyAllTables @NewProjectId

END

GO
/****** Object:  StoredProcedure [dbo].[EmptyAllTables]    Script Date: 7-10-2014 15:00:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Procedure [dbo].[EmptyAllTables] 
	@ProjectId int
as
begin

delete from ExternalReuse where @ProjectId is null or ProjectId = @ProjectId;
delete from InternalReuse where @ProjectId is null or ProjectId = @ProjectId;
delete from Downcall where @ProjectId is null or ProjectId = @ProjectId;
delete from Subtype where @ProjectId is null or ProjectId = @ProjectId;
delete from Super where @ProjectId is null or ProjectId = @ProjectId;
delete from Generic where @ProjectId is null or ProjectId = @ProjectId;
delete from TypeRelation where @ProjectId is null or ProjectId = @ProjectId;
delete from [Type] where @ProjectId is null or ProjectId = @ProjectId;
delete from Project where @ProjectId is null or ProjectId = @ProjectId;
end
GO
/****** Object:  Table [dbo].[Downcall]    Script Date: 7-10-2014 15:00:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Downcall](
	[ProjectId] [int] NOT NULL,
	[FromType] [int] NOT NULL,
	[ToType] [int] NOT NULL,
	[Direct] [bit] NOT NULL,
	[FromMethod] [nvarchar](1000) NOT NULL,
	[ToMethod] [nvarchar](1000) NOT NULL,
	[Declaration] [nvarchar](1000) NOT NULL
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[DynamicUse]    Script Date: 7-10-2014 15:00:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DynamicUse](
	[ProjectId] [int] NOT NULL,
	[StaticOccurrences] [int] NOT NULL,
	[DynamicOccurrences] [int] NOT NULL,
	[VarCount] [int] NOT NULL,
	[NonVarCount] [int] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[ProjectId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[ExternalReuse]    Script Date: 7-10-2014 15:00:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ExternalReuse](
	[ExternalReuseId] [bigint] IDENTITY(1,1) NOT NULL,
	[ProjectId] [int] NOT NULL,
	[FromType] [int] NOT NULL,
	[ToType] [int] NOT NULL,
	[Direct] [bit] NOT NULL,
	[ReuseType] [nvarchar](50) NOT NULL,
	[From] [nvarchar](500) NOT NULL,
	[To] [nvarchar](500) NOT NULL,
 CONSTRAINT [PK__External__3D48C5B27FB00A85] PRIMARY KEY CLUSTERED 
(
	[ExternalReuseId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[Generic]    Script Date: 7-10-2014 15:00:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Generic](
	[GenericId] [bigint] IDENTITY(1,1) NOT NULL,
	[ProjectId] [int] NOT NULL,
	[FromType] [int] NOT NULL,
	[ToType] [int] NOT NULL,
 CONSTRAINT [PK_Generic] PRIMARY KEY CLUSTERED 
(
	[GenericId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[InternalReuse]    Script Date: 7-10-2014 15:00:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[InternalReuse](
	[InternalReuseId] [bigint] IDENTITY(1,1) NOT NULL,
	[ProjectId] [int] NOT NULL,
	[FromType] [int] NOT NULL,
	[ToType] [int] NOT NULL,
	[Direct] [bit] NOT NULL,
	[ReuseType] [nvarchar](50) NOT NULL,
	[From] [nvarchar](500) NOT NULL,
	[To] [nvarchar](500) NOT NULL,
 CONSTRAINT [PK__Internal__C2E2898028F2FB89] PRIMARY KEY CLUSTERED 
(
	[InternalReuseId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[OldProjects]    Script Date: 7-10-2014 15:00:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[OldProjects](
	[ProjectId] [int] IDENTITY(1,1) NOT NULL,
	[Language] [nvarchar](4) NOT NULL,
	[Name] [nvarchar](255) NOT NULL,
	[CreatedDate] [datetime2](7) NOT NULL,
	[LinesOfCode] [bigint] NOT NULL,
	[LinesOfComment] [bigint] NOT NULL,
	[LinesOfBlank] [bigint] NOT NULL,
	[ProjectType] [nvarchar](50) NOT NULL
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[Project]    Script Date: 7-10-2014 15:00:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Project](
	[ProjectId] [int] IDENTITY(1,1) NOT NULL,
	[Language] [nvarchar](4) NOT NULL,
	[Name] [nvarchar](255) NOT NULL,
	[CreatedDate] [datetime2](7) NOT NULL,
	[LinesOfCode] [bigint] NOT NULL,
	[LinesOfComment] [bigint] NOT NULL,
	[LinesOfBlank] [bigint] NOT NULL,
	[ProjectType] [nvarchar](50) NOT NULL,
 CONSTRAINT [PK__Project__761ABEF0EFBC0E06] PRIMARY KEY CLUSTERED 
(
	[ProjectId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[Subtype]    Script Date: 7-10-2014 15:00:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Subtype](
	[SubtypeId] [bigint] IDENTITY(1,1) NOT NULL,
	[ProjectId] [int] NOT NULL,
	[FromType] [int] NOT NULL,
	[ToType] [int] NOT NULL,
	[Direct] [bit] NOT NULL,
	[SubtypeKind] [nvarchar](50) NOT NULL,
	[Source] [nvarchar](500) NOT NULL,
	[Omitted] [bit] NOT NULL,
 CONSTRAINT [PK_Subtype] PRIMARY KEY CLUSTERED 
(
	[SubtypeId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[Super]    Script Date: 7-10-2014 15:00:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Super](
	[ProjectId] [int] NOT NULL,
	[FromType] [int] NOT NULL,
	[ToType] [int] NOT NULL,
	[Declaration] [nvarchar](500) NOT NULL
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[Type]    Script Date: 7-10-2014 15:00:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Type](
	[TypeId] [int] IDENTITY(1,1) NOT NULL,
	[ProjectId] [int] NOT NULL,
	[TypeLocation] [nvarchar](max) NOT NULL,
	[IsOwnCode] [bit] NOT NULL,
 CONSTRAINT [PK__Type__516F03B5F4DC8E09] PRIMARY KEY CLUSTERED 
(
	[TypeId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Table [dbo].[TypeRelation]    Script Date: 7-10-2014 15:00:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[TypeRelation](
	[ProjectId] [int] NOT NULL,
	[FromType] [int] NOT NULL,
	[ToType] [int] NOT NULL,
	[RelationType] [char](2) NOT NULL,
	[DirectRelation] [bit] NOT NULL,
	[Marker] [bit] NOT NULL,
	[Constants] [bit] NOT NULL,
	[SystemType] [bit] NOT NULL,
 CONSTRAINT [PK_TypeRelation] PRIMARY KEY CLUSTERED 
(
	[FromType] ASC,
	[ToType] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  View [dbo].[Category]    Script Date: 7-10-2014 15:00:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view [dbo].[Category]
as
select category.ProjectId, category.FromType, category.ToType
from dbo.TypeRelation category
left join dbo.Subtype subtype
on subtype.FromType = category.FromType
and subtype.ToType = category.ToType
and subtype.ProjectId = category.ProjectId
where SubtypeId is null
and exists (select top 1 1
			from dbo.Subtype siblingSubtype
			where siblingSubtype.ToType = category.ToType)

GO
/****** Object:  View [dbo].[DetailData]    Script Date: 7-10-2014 15:00:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE view [dbo].[DetailData] as 
with supers as (
	select distinct ProjectId, FromType, ToType, 1 as Value from dbo.Super
)
, externalReuse as (
	select distinct ProjectId, FromType, ToType, 1 as Value from dbo.ExternalReuse
)
, internalReuse as (
	select distinct ProjectId, FromType, ToType, 1 as Value from dbo.InternalReuse
)
, subtypes as (
	select distinct ProjectId, FromType, ToType, 1 as Value from dbo.Subtype where omitted = 0
), downcalls as (
	select distinct ProjectId, FromType, ToType, 1 as Value from dbo.Downcall
), generics as (
	select distinct ProjectId, FromType, ToType, 1 as Value from dbo.Generic
)
SELECT tr.ProjectId, 
       RelationType, 
	   tr.FromType,
	   tr.ToType,
	  cast(SystemType as int) as SystemType, 
	  isnull( st.Value, 0) as Subtype,
	  isnull(i.Value, 0) as InternalReuse,
	  isnull( e.Value, 0) as ExternalReuse,
	  isnull(s.Value, 0) as Super,
	  isnull(d.Value, 0) as Downcall,
	  cast(Marker as int) as Marker, 
	  cast(Constants as int) as Constants,
	  isnull(g.Value, 0) as Generic
	  FROM [dbo].[TypeRelation] tr
	  LEFT JOIN supers s
	  on s.ProjectId = tr.ProjectId
	  and s.FromType = tr.FromType
	  and s.ToType = tr.ToType
	  LEFT JOIN internalReuse i
	  on i.ProjectId = tr.ProjectId
	  and i.FromType = tr.FromType
	  and i.ToType = tr.ToType
	  LEFT JOIN externalReuse e
	  on e.ProjectId = tr.ProjectId
	  and e.FromType = tr.FromType
	  and e.ToType = tr.ToType
	  LEFT JOIN subtypes st
	  on  st.ProjectId = tr.ProjectId
	  and st.FromType = tr.FromType
	  and st.ToType = tr.ToType
	  LEFT JOIN downcalls d
	  on  d.ProjectId = tr.ProjectId
	  and d.FromType = tr.FromType
	  and d.ToType = tr.ToType
	  LEFT JOIN generics g
	  on  g.ProjectId = tr.ProjectId
	  and g.FromType = tr.FromType
	  and g.ToType = tr.ToType
	  where DirectRelation = 1





GO
/****** Object:  View [dbo].[Framework]    Script Date: 7-10-2014 15:00:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view [dbo].[Framework] as
select tr.ProjectId, tr.FromType, tr.ToType
from dbo.TypeRelation tr
where tr.DirectRelation = 1
and tr.SystemType = 1
and exists (select top 1 1 
            from dbo.TypeRelation parent 
			where tr.ToType = parent.FromType 
			and parent.DirectRelation = 1 
			and parent.SystemType = 0)
GO
/****** Object:  View [dbo].[Redundant]    Script Date: 7-10-2014 15:00:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE view [dbo].[Redundant] 
as
with cte as (
select ProjectId,FromType as RootFrom, FromType, ToType, 1 as Steps
from dbo.TypeRelation tr where DirectRelation = 1
union all 
select tr.ProjectId, cte.FromType, tr.FromType, tr.ToType, cte.Steps + 1 as Steps
from dbo.TypeRelation tr
join cte 
on cte.ToType = tr.FromType
where DirectRelation = 1
)
select ProjectId, FromType, ToType
from dbo.TypeRelation tr
where exists (select top 1 1 
			  from cte 
			  where tr.ProjectId = cte.ProjectId 
			  and tr.FromType = cte.RootFrom 
			  and tr.ToType = cte.ToType
			  and cte.Steps > 1)
and DirectRelation = 1


GO
/****** Object:  View [dbo].[SingleRelation]    Script Date: 7-10-2014 15:00:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view [dbo].[SingleRelation] 
as 
with allTypes as (
	select FromType as TypeId
	from dbo.TypeRelation
	union all
	select ToType as TypeId
	from dbo.TypeRelation
), singleTypes as (
	select TypeId
	from allTypes
	group by TypeId
	having count(*) = 1
)
select ProjectId, FromType, ToType
from TypeRelation 
where FromType in (select TypeId from singleTypes) 
and ToType in (select TypeId from SingleTypes)

GO
/****** Object:  View [dbo].[RelationAttributes]    Script Date: 7-10-2014 15:00:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE view [dbo].[RelationAttributes]
as
select rel.ProjectId, 
	   fromType.TypeLocation as FromType, 
	   toType.TypeLocation as ToType,
	   rel.DirectRelation as Explicit,
	   case when redundant.ProjectId is null then 0 else 1 end as Redundant,
	   case when rel.DirectRelation = 0 then 1 else 0 end as ImplicitKnown,
	   rel.SystemType as UserDefined,
	   rel.RelationType,
	   rel.Marker,
	   case when framework.ProjectId is null then 0 else 1 end as Framework,
	   case when category.ProjectId is null then 0 else 1 end as Category,
	   rel.Constants,
	   dd.Generic as Generic,
	   case when single.ProjectId is null then 0 else 1 end as Single,
	   dd.Downcall,
	   dd.Super as UpcallConstructor,
	   dd.InternalReuse as Upcall,
	   dd.ExternalReuse,
	   dd.Subtype
from dbo.TypeRelation rel
join dbo.[Type] fromType on fromType.TypeId = rel.FromType
join dbo.[Type] toType on toType.TypeId = rel.ToType
join dbo.DetailData dd
on rel.FromType = dd.FromType
and rel.ToType = dd.ToType
left join dbo.Redundant redundant
on rel.FromType = redundant.FromType
and rel.ToType = redundant.ToType
left join dbo.Framework framework
on rel.FromType = framework.FromType
and rel.ToType = framework.ToType
left join dbo.Category category
on rel.FromType = category.FromType
and rel.ToType = category.ToType
left join dbo.SingleRelation single
on rel.FromType = single.FromType
and rel.ToType = single.ToType

GO
/****** Object:  View [dbo].[BaseMetrics]    Script Date: 7-10-2014 15:00:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE view [dbo].[BaseMetrics] as
select a.ProjectId,
	a.FromType,
	a.ToType,
--nExplicitCC	Number of explicit userdefined cc edges
--- {(UserDefined) and (Explicit) and (CC)}
	case when UserDefined = 1 and Explicit = 1 and RelationType = 'CC' 
	then 1.0 else 0.0 end as nExplicitCC,
--nCCUsed	Explicit class edges for which some subtype use or reuse use was seen 
--- {(UserDefined) and (Explicit) and (CC) and (DirectExReuseField or IndirectExReuseField or DirectExReuseMethod 
---or IndirectExReuseMethod or DirectSubtype or IndirectSubtype or UpcallField or UpcallMethod)}
	case when UserDefined = 1 and Explicit = 1 and RelationType = 'CC'
	and (ExternalReuse = 1 or Subtype = 1 or Upcall = 1) 
	then 1.0 else 0.0 end as nCCUsed,
--nCCDC	Number of explicit CC edges that have Downcall use 
--- {(UserDefined) and (Explicit) and (CC) and (Downcall)}
	case when UserDefined = 1 and Explicit = 1 and RelationType = 'CC' and Downcall = 1 
	then 1.0 else 0.0 end as nCCDC,
--nCCSubtype	Used system CC edges for which subtype use was seen 
--- {(UserDefined) and (Explicit) and (CC) and (DirectSubtype or IndirectSubtype)}
	case when UserDefined = 1 and Explicit = 1 and RelationType = 'CC' and Subtype = 1
	then 1.0 else 0.0 end as nCCSubtype,
--nCCSubtype	Used system CC edges for which subtype use was seen 
--- {(UserDefined) and (Explicit) and (CC) and (DirectSubtype or IndirectSubtype)}
	case when UserDefined = 1 and Explicit = 1 and RelationType = 'CC' and (Subtype = 1 or Generic = 1 or Framework = 1)
	then 1.0 else 0.0 end as nCCSuspectedSubtype,
--nCCExreuseNoSubtype	Used system CC edges for which no subtype use was seen, but external reuse use was seen 
--- {(UserDefined) and (Explicit) and (CC) and (DirectExReuseField or IndirectExReuseField or DirectExReuseMethod or IndirectExReuseMethod) 
--- and (not DirectSubtype) and (not IndirectSubtype)}
	case when UserDefined = 1 and Explicit = 1 and RelationType = 'CC' and ExternalReuse = 1 and Subtype = 0
	then 1.0 else 0.0 end as nCCExreuseNoSubtype,
--nCCUsedOnlyInRe	Used system CC edges for which only internal reuse was seen 
--- {(UserDefined) and (Explicit) and (CC) 
--and (not DirectExReuseField) and (notIndirectExReuseField) and (not DirectExReuseMethod) and (not IndirectExReuseMethod) a
--nd (not DirectSubtype) and (not IndirectSubtype) and (UpcallField or UpcallMethod)}
	case when UserDefined = 1 and Explicit = 1 and RelationType = 'CC' and ExternalReuse = 0 and Subtype = 0 and Upcall = 1
	then 1.0 else 0.0 end as nCCUsedOnlyInRe,
--nCCUnexplSuper	Explict system edges that have no use or explanation but super constructor calls 
--- {(UserDefined) and (Explicit) and (CC) and (not DirectExReuseField) and (not IndirectExReuseField) and (not DirectExReuseMethod) 
--and (not IndirectExReuseMethod) and (not DirectSubtype) and (not IndirectSubtype) and (not UpcallField) and (not UpcallMethod) 
--and (not Downcall) and (not ConstantsClass) and (not ConstantsInterface) and (not Marker) and (notFramework) and (not GenericUse) 
--and (UpcallConstructorSuper)}
	case when UserDefined = 1 and Explicit = 1 and RelationType = 'CC' and ExternalReuse = 0 and Subtype = 0 and Upcall = 0
	and Downcall = 0 and Constants = 0 and Marker = 0 and Framework = 0 and Generic = 0 and UpcallConstructor = 1
	then 1.0 else 0.0 end as nCCUnexplSuper,
--nCCUnexplCategory	Explict system edges that have no use or explanation (incl. super constructor calls) but has category use 
--- {(UserDefined) and (Explicit) and (CC) and (not DirectExReuseField) and (not IndirectExReuseField) and (not DirectExReuseMethod) 
--and (not IndirectExReuseMethod) and (not DirectSubtype) and (not IndirectSubtype) and (not UpcallField) and (not UpcallMethod) 
--and (not Downcall) and (not ConstantsClass) and (not ConstantsInterface) and (notMarker) and (not Framework) and (not GenericUse) 
--and (not UpcallConstructorSuper) and (Category)}
	case when UserDefined = 1 and Explicit = 1 and RelationType = 'CC' and ExternalReuse = 0 and Subtype = 0 and Upcall = 0
	and Downcall = 0 and Constants = 0 and Marker = 0 and Framework = 0 and Generic = 0 and UpcallConstructor = 0 and Category = 1
	then 1.0 else 0.0 end as nCCUnexplCategory,
--nCCUnknown	Explicit system class edges that no use or explanation is known (nCCUnused = nCCExplained+nCCUnknown) 
--- {(UserDefined) and (Explicit) and (CC) and (not DirectExReuseField) and (not IndirectExReuseField) and (not DirectExReuseMethod) 
---and (not IndirectExReuseMethod) and (not DirectSubtype) and (not IndirectSubtype) and (not UpcallField) 
---and (not UpcallMethod) and (not Downcall) and (not ConstantsClass) and (not ConstantsInterface) and (not Marker) 
---and (not Framework) and (not GenericUse) and (not UpcallConstructorSuper) and (not Category)}
	case when UserDefined = 1 and Explicit = 1 and RelationType = 'CC' and ExternalReuse = 0 and Subtype = 0 and Upcall = 0
	and Downcall = 0 and Constants = 0 and Marker = 0 and Framework = 0 and Generic = 0 and UpcallConstructor = 0 and Category = 0
	then 1.0 else 0.0 end as nCCUnknown,
--nExplicitCI	Explicit edges between user-defined classes and user-defined interfaces 
--- {(UserDefined) and (Explicit) and (CI)}
	case when UserDefined = 1 and Explicit = 1 and RelationType = 'CI' 
	then 1.0 else 0.0 end as nExplicitCI,
--nOnlyCISubtype	Edges between classes and interfaces for which subtype use was seen (the only use possible for such edges) 
--- {(UserDefined) and (Explicit) and (CI) and (DirectSubtype or IndirectSubtype)}
	case when UserDefined = 1 and Explicit = 1 and RelationType = 'CI' and Subtype = 1
	then 1.0 else 0.0 end as nOnlyCISubtype,
--nExplainedCI	Edges from class to interface with no subtype use seen, but with one of Framework, Generic, etc (not Category) 
--- {(UserDefined) and (Explicit) and (CI) and (not DirectSubtype) and (not IndirectSubtype) 
---and (Framework or GenericUse or Marker or ConstantsInterface or ConstantsClass)}
	case when UserDefined = 1 and Explicit = 1 and RelationType = 'CI' and Subtype = 0 
	and (Framework = 1 or Generic = 1 or Marker = 1 or Constants = 1)
	then 1.0 else 0.0 end as nExplainedCI,
--nCategoryExplCI	Edges for which no subtype use or other explanation was seen, but which have Category 
--- {(UserDefined) and (Explicit) and (CI) and (notDirectSubtype) and (not IndirectSubtype) and (not Framework) 
--- and (not GenericUse) and (not Marker) and (not ConstantsInterface) and (notConstantsClass) and (Category)}
	case when UserDefined = 1 and Explicit = 1 and RelationType = 'CI' and Subtype = 0 
	and Framework = 0 and Generic = 0 and Marker = 0 and Constants = 0 and Category = 1
	then 1.0 else 0.0 end as nCategoryExplCI,
--nUnexplainedCI	Edges from class to interface with no subtype use seen or explained (including Category) 
--- {(UserDefined) and (Explicit) and (CI) and (notDirectSubtype) and (not IndirectSubtype) and (not Framework) 
--- and (not GenericUse) and (not Marker) and (not ConstantsInterface) and (notConstantsClass) and (not Category)}
	case when UserDefined = 1 and Explicit = 1 and RelationType = 'CI' and Subtype = 0 
	and Framework = 0 and Generic = 0 and Marker = 0 and Constants = 0 and Category = 0
	then 1.0 else 0.0 end as nUnexplainedCI,
--nExplicitII	Explicit edges between user-defined interfaces 
--- {(UserDefined) and (Explicit) and (II)}
	case when UserDefined = 1 and Explicit = 1 and RelationType = 'II' 
	then 1.0 else 0.0 end as nExplicitII,
--nIISubtype	Edges between interfaces with at least subtype use 
--- {(UserDefined) and (Explicit) and (II) and (DirectSubtype or IndirectSubtype)}
	case when UserDefined = 1 and Explicit = 1 and RelationType = 'II' and Subtype = 1
	then 1.0 else 0.0 end as nIISubtype,
--nOnlyIIReuse	Edges between interfaces for which reuse was seen but not subtype 
--- {(UserDefined) and (Explicit) and (II) 
--- and (DirectExReuseField orIndirectExReuseField or DirectExReuseMethod or IndirectExReuseMethod) 
--- and (not DirectSubtype) and (not IndirectSubtype)}
	case when UserDefined = 1 and Explicit = 1 and RelationType = 'II' and Subtype = 0 and ExternalReuse = 1
	then 1.0 else 0.0 end as nOnlyIIReuse,
--nExplainedII	Unused edges between interface with some explanation (not category) 
--- {(UserDefined) and (Explicit) and (II) and (not DirectExReuseField) and (notIndirectExReuseField) 
--- and (not DirectExReuseMethod) and (not IndirectExReuseMethod) and (not DirectSubtype) and (not IndirectSubtype) 
--  and (Framework or GenericUse or Marker or ConstantsInterface or ConstantsClass)}
	case when UserDefined = 1 and Explicit = 1 and RelationType = 'II' and Subtype = 0 and ExternalReuse = 0
	and (Framework = 1 or Generic = 1 or Marker = 1 or Constants = 1)
	then 1.0 else 0.0 end as nExplainedII,
--nCategoryExplII	Edges for which no use or other explanation has been seen, but which have Category 
--- {(UserDefined) and (Explicit) and (II) and (notDirectExReuseField) and (not IndirectExReuseField) 
--- and (not DirectExReuseMethod) and (not IndirectExReuseMethod) and (not DirectSubtype) and (notIndirectSubtype) 
--- and (not Framework) and (not GenericUse) and (not Marker) and (not ConstantsInterface) and (not ConstantsClass) and (Category)}
	case when UserDefined = 1 and Explicit = 1 and RelationType = 'II' and Subtype = 0 and ExternalReuse = 0
	and Framework = 0 and Generic = 0 and Marker = 0 and Constants = 0 and Category = 1
	then 1.0 else 0.0 end as nCategoryExplII,
--nUnexplainedII	Edges between interfaces with no explanation (including Category)
--- {(UserDefined) and (Explicit) and (II) and (not DirectExReuseField) and (notIndirectExReuseField) 
--- and (not DirectExReuseMethod) and (not IndirectExReuseMethod) and (not DirectSubtype) and (not IndirectSubtype) 
--- and (notFramework) and (not GenericUse) and (not Marker) and (not ConstantsInterface) and (not ConstantsClass) and (not Category)}
	case when UserDefined = 1 and Explicit = 1 and RelationType = 'II' and ExternalReuse = 0 and Subtype = 0 
	and Framework = 0 and Generic = 0 and Marker = 0 and Constants = 0 and Category = 0
	then 1.0 else 0.0 end as nUnexplainedII
from dbo.RelationAttributes a


GO
/****** Object:  View [dbo].[ProjectMetrics]    Script Date: 7-10-2014 15:00:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE view [dbo].[ProjectMetrics] as 
with summarizedMetrics as (
select  ProjectId,
		sum(nExplicitCC) as nExplicitCC,
		sum(nCCUsed) as nCCUsed,
		sum(nCCDC) as nCCDC,
		sum(nCCSubtype) as nCCSubtype,
		sum(nCCSuspectedSubtype) as nCCSuspectedSubtype,
		sum(nCCExreuseNoSubtype) as nCCExreuseNoSubtype,
		sum(nCCUsedOnlyInRe) as nCCUsedOnlyInRe,
		sum(nCCUnexplSuper) as nCCUnexplSuper,
		sum(nCCUnexplCategory) as nCCUnexplCategory,
		sum(nCCUnknown) as nCCUnknown,
		sum(nExplicitCI) as nExplicitCI,
		sum(nOnlyCISubtype) as nOnlyCISubtype,
		sum(nExplainedCI) as nExplainedCI,
		sum(nCategoryExplCI) as nCategoryExplCI,
		sum(nUnexplainedCI) as nUnexplainedCI,
		sum(nExplicitII) as nExplicitII,
		sum(nIISubtype) as nIISubtype,
		sum(nOnlyIIReuse) as nOnlyIIReuse,
		sum(nExplainedII) as nExplainedII,
		sum(nCategoryExplII) as nCategoryExplII,
		sum(nUnexplainedII) as nUnexplainedII
		from BaseMetrics m
		group by ProjectId)
select  m.ProjectId,
		p.Language,
		p.ProjectType,
		p.Name,
		p.LinesOfCode,
		cast(nExplicitCC as int) as nExplicitCC,
		cast(nCCUsed as int) as nCCUsed,
		cast((nCCUsed/nullif(nExplicitCC,0)) as float) as pCCUsed,
		cast(nCCDC as int) as nCCDC,
		cast((nCCDC/nullif(nExplicitCC,0)) as float) as pCCDC,
		cast(nCCSubtype as int) as nCCSubtype,
		cast((nCCSubtype/nullif(nCCUsed,0)) as float) as pCCSubtype,
		cast(nCCSuspectedSubtype as int) as nCCSuspectedSubtype,
		cast((nCCSuspectedSubtype/nullif(nCCUsed,0)) as float) as pCCSuspectedSubtype,
		cast(nCCExreuseNoSubtype as int) as nCCExreuseNoSubtype,
		cast((nCCExreuseNoSubtype/nullif(nCCUsed,0)) as float) as pCCExreuseNoSubtype,
		cast(nCCUsedOnlyInRe as int) as nCCUsedOnlyInRe,
		cast((nCCUsedOnlyInRe/nullif(nCCUsed,0)) as float) as pCCUsedOnlyInRe,
		cast(nCCUnexplSuper as int) as nCCUnexplSuper,
		cast((nCCUnexplSuper/nullif(nExplicitCC,0)) as float) as pCCUnexplSuper,
		cast(nCCUnexplCategory as int) as nCCUnexplCategory,
		cast((nCCUnexplCategory/nullif(nExplicitCC,0)) as float) as pCCUnexplCategory,
		cast(nCCUnknown as int) as nCCUnknown,
		cast((nCCUnknown/nullif(nExplicitCC,0)) as float) as pCCUnknown,
		cast(nExplicitCI as int) as nExplicitCI,
		cast(nOnlyCISubtype as int) as nOnlyCISubtype,
		cast((nOnlyCISubtype/nullif(nExplicitCI,0)) as float) as pOnlyCISubtype,
		cast(nExplainedCI as int) as nExplainedCI,
		cast((nExplainedCI/nullif(nExplicitCI,0)) as float) as pExplainedCI,
		cast(nCategoryExplCI as int) as nCategoryExplCI,
		cast((nCategoryExplCI/nullif(nExplicitCI,0)) as float) as pCategoryExplCI,
		cast(nUnexplainedCI as int) as nUnexplainedCI,
		cast((nUnexplainedCI/nullif(nExplicitCI,0)) as float) as pUnexplainedCI,
		cast(nExplicitII as int) as nExplicitII,
		cast(nIISubtype as int) as nIISubtype,
		cast((nIISubtype/nullif(nExplicitII,0)) as float) as pIISubtype,
		cast(nOnlyIIReuse as int) as nOnlyIIReuse,
		cast((nOnlyIIReuse/nullif(nExplicitII,0)) as float) as pOnlyIIReuse,
		cast(nExplainedII as int) as nExplainedII,
		cast((nExplainedII/nullif(nExplicitII,0)) as float) as pExplainedII,
		cast(nCategoryExplII as int) as nCategoryExplII,
		cast((nCategoryExplII/nullif(nExplicitII,0)) as float) as pCategoryExplII,
		cast(nUnexplainedII as int) as nUnexplainedII,
		cast((nUnexplainedII/nullif(nExplicitII,0)) as float) as pUnexplainedII
from summarizedMetrics m
join Project p
on m.ProjectId = p.ProjectId


GO
/****** Object:  View [dbo].[DetailDataNoTCT]    Script Date: 7-10-2014 15:00:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE view [dbo].[DetailDataNoTCT] as 
with supers as (
	select distinct ProjectId, FromType, ToType, 1 as Value from dbo.Super
)
, externalReuse as (
	select distinct ProjectId, FromType, ToType, 1 as Value from dbo.ExternalReuse
)
, internalReuse as (
	select distinct ProjectId, FromType, ToType, 1 as Value from dbo.InternalReuse
)
, subtypes as (
	select distinct ProjectId, FromType, ToType, 1 as Value from dbo.Subtype where SubtypeKind not in ('ThisChangingType', 'thisChangingType()')
), downcalls as (
	select distinct ProjectId, FromType, ToType, 1 as Value from dbo.Downcall
), generics as (
	select distinct ProjectId, FromType, ToType, 1 as Value from dbo.Generic
)
SELECT tr.ProjectId, 
       RelationType, 
	   tr.FromType,
	   tr.ToType,
	  cast(SystemType as int) as SystemType, 
	  isnull( st.Value, 0) as Subtype,
	  isnull(i.Value, 0) as InternalReuse,
	  isnull( e.Value, 0) as ExternalReuse,
	  isnull(s.Value, 0) as Super,
	  isnull(d.Value, 0) as Downcall,
	  cast(Marker as int) as Marker, 
	  cast(Constants as int) as Constants,
	  isnull(g.Value, 0) as Generic
	  FROM [dbo].[TypeRelation] tr
	  LEFT JOIN supers s
	  on s.ProjectId = tr.ProjectId
	  and s.FromType = tr.FromType
	  and s.ToType = tr.ToType
	  LEFT JOIN internalReuse i
	  on i.ProjectId = tr.ProjectId
	  and i.FromType = tr.FromType
	  and i.ToType = tr.ToType
	  LEFT JOIN externalReuse e
	  on e.ProjectId = tr.ProjectId
	  and e.FromType = tr.FromType
	  and e.ToType = tr.ToType
	  LEFT JOIN subtypes st
	  on  st.ProjectId = tr.ProjectId
	  and st.FromType = tr.FromType
	  and st.ToType = tr.ToType
	  LEFT JOIN downcalls d
	  on  d.ProjectId = tr.ProjectId
	  and d.FromType = tr.FromType
	  and d.ToType = tr.ToType
	  LEFT JOIN generics g
	  on  g.ProjectId = tr.ProjectId
	  and g.FromType = tr.FromType
	  and g.ToType = tr.ToType
	  where DirectRelation = 1


GO
/****** Object:  View [dbo].[RelationAttributesNoTCT]    Script Date: 7-10-2014 15:00:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE view [dbo].[RelationAttributesNoTCT]
as
select rel.ProjectId, 
	   fromType.TypeLocation as FromType, 
	   toType.TypeLocation as ToType,
	   rel.DirectRelation as Explicit,
	   case when redundant.ProjectId is null then 0 else 1 end as Redundant,
	   case when rel.DirectRelation = 0 then 1 else 0 end as ImplicitKnown,
	   rel.SystemType as UserDefined,
	   rel.RelationType,
	   rel.Marker,
	   case when framework.ProjectId is null then 0 else 1 end as Framework,
	   case when category.ProjectId is null then 0 else 1 end as Category,
	   rel.Constants,
	   dd.Generic as Generic,
	   case when single.ProjectId is null then 0 else 1 end as Single,
	   dd.Downcall,
	   dd.Super as UpcallConstructor,
	   dd.InternalReuse as Upcall,
	   dd.ExternalReuse,
	   dd.Subtype
from dbo.TypeRelation rel
join dbo.[Type] fromType on fromType.TypeId = rel.FromType
join dbo.[Type] toType on toType.TypeId = rel.ToType
join dbo.DetailDataNoTCT dd
on rel.FromType = dd.FromType
and rel.ToType = dd.ToType
left join dbo.Redundant redundant
on rel.FromType = redundant.FromType
and rel.ToType = redundant.ToType
left join dbo.Framework framework
on rel.FromType = framework.FromType
and rel.ToType = framework.ToType
left join dbo.Category category
on rel.FromType = category.FromType
and rel.ToType = category.ToType
left join dbo.SingleRelation single
on rel.FromType = single.FromType
and rel.ToType = single.ToType


GO
/****** Object:  View [dbo].[BaseMetricsNoTCT]    Script Date: 7-10-2014 15:00:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE view [dbo].[BaseMetricsNoTCT] as
select a.ProjectId,
	a.FromType,
	a.ToType,
--nExplicitCC	Number of explicit userdefined cc edges
--- {(UserDefined) and (Explicit) and (CC)}
	case when UserDefined = 1 and Explicit = 1 and RelationType = 'CC' 
	then 1.0 else 0.0 end as nExplicitCC,
--nCCUsed	Explicit class edges for which some subtype use or reuse use was seen 
--- {(UserDefined) and (Explicit) and (CC) and (DirectExReuseField or IndirectExReuseField or DirectExReuseMethod 
---or IndirectExReuseMethod or DirectSubtype or IndirectSubtype or UpcallField or UpcallMethod)}
	case when UserDefined = 1 and Explicit = 1 and RelationType = 'CC'
	and (ExternalReuse = 1 or Subtype = 1 or Upcall = 1) 
	then 1.0 else 0.0 end as nCCUsed,
--nCCDC	Number of explicit CC edges that have Downcall use 
--- {(UserDefined) and (Explicit) and (CC) and (Downcall)}
	case when UserDefined = 1 and Explicit = 1 and RelationType = 'CC' and Downcall = 1 
	then 1.0 else 0.0 end as nCCDC,
--nCCSubtype	Used system CC edges for which subtype use was seen 
--- {(UserDefined) and (Explicit) and (CC) and (DirectSubtype or IndirectSubtype)}
	case when UserDefined = 1 and Explicit = 1 and RelationType = 'CC' and Subtype = 1
	then 1.0 else 0.0 end as nCCSubtype,
--nCCSubtype	Used system CC edges for which subtype use was seen 
--- {(UserDefined) and (Explicit) and (CC) and (DirectSubtype or IndirectSubtype)}
	case when UserDefined = 1 and Explicit = 1 and RelationType = 'CC' and (Subtype = 1 or Generic = 1 Or Framework =1 )
	then 1.0 else 0.0 end as nCCSuspectedSubtype,
--nCCExreuseNoSubtype	Used system CC edges for which no subtype use was seen, but external reuse use was seen 
--- {(UserDefined) and (Explicit) and (CC) and (DirectExReuseField or IndirectExReuseField or DirectExReuseMethod or IndirectExReuseMethod) 
--- and (not DirectSubtype) and (not IndirectSubtype)}
	case when UserDefined = 1 and Explicit = 1 and RelationType = 'CC' and ExternalReuse = 1 and Subtype = 0
	then 1.0 else 0.0 end as nCCExreuseNoSubtype,
--nCCUsedOnlyInRe	Used system CC edges for which only internal reuse was seen 
--- {(UserDefined) and (Explicit) and (CC) 
--and (not DirectExReuseField) and (notIndirectExReuseField) and (not DirectExReuseMethod) and (not IndirectExReuseMethod) a
--nd (not DirectSubtype) and (not IndirectSubtype) and (UpcallField or UpcallMethod)}
	case when UserDefined = 1 and Explicit = 1 and RelationType = 'CC' and ExternalReuse = 0 and Subtype = 0 and Upcall = 1
	then 1.0 else 0.0 end as nCCUsedOnlyInRe,
--nCCUnexplSuper	Explict system edges that have no use or explanation but super constructor calls 
--- {(UserDefined) and (Explicit) and (CC) and (not DirectExReuseField) and (not IndirectExReuseField) and (not DirectExReuseMethod) 
--and (not IndirectExReuseMethod) and (not DirectSubtype) and (not IndirectSubtype) and (not UpcallField) and (not UpcallMethod) 
--and (not Downcall) and (not ConstantsClass) and (not ConstantsInterface) and (not Marker) and (notFramework) and (not GenericUse) 
--and (UpcallConstructorSuper)}
	case when UserDefined = 1 and Explicit = 1 and RelationType = 'CC' and ExternalReuse = 0 and Subtype = 0 and Upcall = 0
	and Downcall = 0 and Constants = 0 and Marker = 0 and Framework = 0 and Generic = 0 and UpcallConstructor = 1
	then 1.0 else 0.0 end as nCCUnexplSuper,
--nCCUnexplCategory	Explict system edges that have no use or explanation (incl. super constructor calls) but has category use 
--- {(UserDefined) and (Explicit) and (CC) and (not DirectExReuseField) and (not IndirectExReuseField) and (not DirectExReuseMethod) 
--and (not IndirectExReuseMethod) and (not DirectSubtype) and (not IndirectSubtype) and (not UpcallField) and (not UpcallMethod) 
--and (not Downcall) and (not ConstantsClass) and (not ConstantsInterface) and (notMarker) and (not Framework) and (not GenericUse) 
--and (not UpcallConstructorSuper) and (Category)}
	case when UserDefined = 1 and Explicit = 1 and RelationType = 'CC' and ExternalReuse = 0 and Subtype = 0 and Upcall = 0
	and Downcall = 0 and Constants = 0 and Marker = 0 and Framework = 0 and Generic = 0 and UpcallConstructor = 0 and Category = 1
	then 1.0 else 0.0 end as nCCUnexplCategory,
--nCCUnknown	Explicit system class edges that no use or explanation is known (nCCUnused = nCCExplained+nCCUnknown) 
--- {(UserDefined) and (Explicit) and (CC) and (not DirectExReuseField) and (not IndirectExReuseField) and (not DirectExReuseMethod) 
---and (not IndirectExReuseMethod) and (not DirectSubtype) and (not IndirectSubtype) and (not UpcallField) 
---and (not UpcallMethod) and (not Downcall) and (not ConstantsClass) and (not ConstantsInterface) and (not Marker) 
---and (not Framework) and (not GenericUse) and (not UpcallConstructorSuper) and (not Category)}
	case when UserDefined = 1 and Explicit = 1 and RelationType = 'CC' and ExternalReuse = 0 and Subtype = 0 and Upcall = 0
	and Downcall = 0 and Constants = 0 and Marker = 0 and Framework = 0 and Generic = 0 and UpcallConstructor = 0 and Category = 0
	then 1.0 else 0.0 end as nCCUnknown,
--nExplicitCI	Explicit edges between user-defined classes and user-defined interfaces 
--- {(UserDefined) and (Explicit) and (CI)}
	case when UserDefined = 1 and Explicit = 1 and RelationType = 'CI' 
	then 1.0 else 0.0 end as nExplicitCI,
--nOnlyCISubtype	Edges between classes and interfaces for which subtype use was seen (the only use possible for such edges) 
--- {(UserDefined) and (Explicit) and (CI) and (DirectSubtype or IndirectSubtype)}
	case when UserDefined = 1 and Explicit = 1 and RelationType = 'CI' and Subtype = 1
	then 1.0 else 0.0 end as nOnlyCISubtype,
--nExplainedCI	Edges from class to interface with no subtype use seen, but with one of Framework, Generic, etc (not Category) 
--- {(UserDefined) and (Explicit) and (CI) and (not DirectSubtype) and (not IndirectSubtype) 
---and (Framework or GenericUse or Marker or ConstantsInterface or ConstantsClass)}
	case when UserDefined = 1 and Explicit = 1 and RelationType = 'CI' and Subtype = 0 
	and (Framework = 1 or Generic = 1 or Marker = 1 or Constants = 1)
	then 1.0 else 0.0 end as nExplainedCI,
--nCategoryExplCI	Edges for which no subtype use or other explanation was seen, but which have Category 
--- {(UserDefined) and (Explicit) and (CI) and (notDirectSubtype) and (not IndirectSubtype) and (not Framework) 
--- and (not GenericUse) and (not Marker) and (not ConstantsInterface) and (notConstantsClass) and (Category)}
	case when UserDefined = 1 and Explicit = 1 and RelationType = 'CI' and Subtype = 0 
	and Framework = 0 and Generic = 0 and Marker = 0 and Constants = 0 and Category = 1
	then 1.0 else 0.0 end as nCategoryExplCI,
--nUnexplainedCI	Edges from class to interface with no subtype use seen or explained (including Category) 
--- {(UserDefined) and (Explicit) and (CI) and (notDirectSubtype) and (not IndirectSubtype) and (not Framework) 
--- and (not GenericUse) and (not Marker) and (not ConstantsInterface) and (notConstantsClass) and (not Category)}
	case when UserDefined = 1 and Explicit = 1 and RelationType = 'CI' and Subtype = 0 
	and Framework = 0 and Generic = 0 and Marker = 0 and Constants = 0 and Category = 0
	then 1.0 else 0.0 end as nUnexplainedCI,
--nExplicitII	Explicit edges between user-defined interfaces 
--- {(UserDefined) and (Explicit) and (II)}
	case when UserDefined = 1 and Explicit = 1 and RelationType = 'II' 
	then 1.0 else 0.0 end as nExplicitII,
--nIISubtype	Edges between interfaces with at least subtype use 
--- {(UserDefined) and (Explicit) and (II) and (DirectSubtype or IndirectSubtype)}
	case when UserDefined = 1 and Explicit = 1 and RelationType = 'II' and Subtype = 1
	then 1.0 else 0.0 end as nIISubtype,
--nOnlyIIReuse	Edges between interfaces for which reuse was seen but not subtype 
--- {(UserDefined) and (Explicit) and (II) 
--- and (DirectExReuseField orIndirectExReuseField or DirectExReuseMethod or IndirectExReuseMethod) 
--- and (not DirectSubtype) and (not IndirectSubtype)}
	case when UserDefined = 1 and Explicit = 1 and RelationType = 'II' and Subtype = 0 and ExternalReuse = 1
	then 1.0 else 0.0 end as nOnlyIIReuse,
--nExplainedII	Unused edges between interface with some explanation (not category) 
--- {(UserDefined) and (Explicit) and (II) and (not DirectExReuseField) and (notIndirectExReuseField) 
--- and (not DirectExReuseMethod) and (not IndirectExReuseMethod) and (not DirectSubtype) and (not IndirectSubtype) 
--  and (Framework or GenericUse or Marker or ConstantsInterface or ConstantsClass)}
	case when UserDefined = 1 and Explicit = 1 and RelationType = 'II' and Subtype = 0 and ExternalReuse = 0
	and (Framework = 1 or Generic = 1 or Marker = 1 or Constants = 1)
	then 1.0 else 0.0 end as nExplainedII,
--nCategoryExplII	Edges for which no use or other explanation has been seen, but which have Category 
--- {(UserDefined) and (Explicit) and (II) and (notDirectExReuseField) and (not IndirectExReuseField) 
--- and (not DirectExReuseMethod) and (not IndirectExReuseMethod) and (not DirectSubtype) and (notIndirectSubtype) 
--- and (not Framework) and (not GenericUse) and (not Marker) and (not ConstantsInterface) and (not ConstantsClass) and (Category)}
	case when UserDefined = 1 and Explicit = 1 and RelationType = 'II' and Subtype = 0 and ExternalReuse = 0
	and Framework = 0 and Generic = 0 and Marker = 0 and Constants = 0 and Category = 1
	then 1.0 else 0.0 end as nCategoryExplII,
--nUnexplainedII	Edges between interfaces with no explanation (including Category)
--- {(UserDefined) and (Explicit) and (II) and (not DirectExReuseField) and (notIndirectExReuseField) 
--- and (not DirectExReuseMethod) and (not IndirectExReuseMethod) and (not DirectSubtype) and (not IndirectSubtype) 
--- and (notFramework) and (not GenericUse) and (not Marker) and (not ConstantsInterface) and (not ConstantsClass) and (not Category)}
	case when UserDefined = 1 and Explicit = 1 and RelationType = 'II' and ExternalReuse = 0 and Subtype = 0 
	and Framework = 0 and Generic = 0 and Marker = 0 and Constants = 0 and Category = 0
	then 1.0 else 0.0 end as nUnexplainedII
from dbo.RelationAttributesNoTCT a




GO
/****** Object:  View [dbo].[ProjectMetricsNoTCT]    Script Date: 7-10-2014 15:00:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE view [dbo].[ProjectMetricsNoTCT] as 
with summarizedMetrics as (
select  ProjectId,
		sum(nExplicitCC) as nExplicitCC,
		sum(nCCUsed) as nCCUsed,
		sum(nCCDC) as nCCDC,
		sum(nCCSubtype) as nCCSubtype,
		sum(nCCSuspectedSubtype) as nCCSuspectedSubtype,
		sum(nCCExreuseNoSubtype) as nCCExreuseNoSubtype,
		sum(nCCUsedOnlyInRe) as nCCUsedOnlyInRe,
		sum(nCCUnexplSuper) as nCCUnexplSuper,
		sum(nCCUnexplCategory) as nCCUnexplCategory,
		sum(nCCUnknown) as nCCUnknown,
		sum(nExplicitCI) as nExplicitCI,
		sum(nOnlyCISubtype) as nOnlyCISubtype,
		sum(nExplainedCI) as nExplainedCI,
		sum(nCategoryExplCI) as nCategoryExplCI,
		sum(nUnexplainedCI) as nUnexplainedCI,
		sum(nExplicitII) as nExplicitII,
		sum(nIISubtype) as nIISubtype,
		sum(nOnlyIIReuse) as nOnlyIIReuse,
		sum(nExplainedII) as nExplainedII,
		sum(nCategoryExplII) as nCategoryExplII,
		sum(nUnexplainedII) as nUnexplainedII
		from BaseMetricsNoTCT m
		group by ProjectId)
select  m.ProjectId,
		p.Language,
		p.ProjectType,
		p.Name,
		p.LinesOfCode,
		cast(nExplicitCC as int) as nExplicitCC,
		cast(nCCUsed as int) as nCCUsed,
		cast((nCCUsed/nullif(nExplicitCC,0)) as float) as pCCUsed,
		cast(nCCDC as int) as nCCDC,
		cast((nCCDC/nullif(nExplicitCC,0)) as float) as pCCDC,
		cast(nCCSubtype as int) as nCCSubtype,
		cast((nCCSubtype/nullif(nCCUsed,0)) as float) as pCCSubtype,
		cast(nCCSuspectedSubtype as int) as nCCSuspectedSubtype,
		cast((nCCSuspectedSubtype/nullif(nCCUsed,0)) as float) as pCCSuspectedSubtype,
		cast(nCCExreuseNoSubtype as int) as nCCExreuseNoSubtype,
		cast((nCCExreuseNoSubtype/nullif(nCCUsed,0)) as float) as pCCExreuseNoSubtype,
		cast(nCCUsedOnlyInRe as int) as nCCUsedOnlyInRe,
		cast((nCCUsedOnlyInRe/nullif(nCCUsed,0)) as float) as pCCUsedOnlyInRe,
		cast(nCCUnexplSuper as int) as nCCUnexplSuper,
		cast((nCCUnexplSuper/nullif(nExplicitCC,0)) as float) as pCCUnexplSuper,
		cast(nCCUnexplCategory as int) as nCCUnexplCategory,
		cast((nCCUnexplCategory/nullif(nExplicitCC,0)) as float) as pCCUnexplCategory,
		cast(nCCUnknown as int) as nCCUnknown,
		cast((nCCUnknown/nullif(nExplicitCC,0)) as float) as pCCUnknown,
		cast(nExplicitCI as int) as nExplicitCI,
		cast(nOnlyCISubtype as int) as nOnlyCISubtype,
		cast((nOnlyCISubtype/nullif(nExplicitCI,0)) as float) as pOnlyCISubtype,
		cast(nExplainedCI as int) as nExplainedCI,
		cast((nExplainedCI/nullif(nExplicitCI,0)) as float) as pExplainedCI,
		cast(nCategoryExplCI as int) as nCategoryExplCI,
		cast((nCategoryExplCI/nullif(nExplicitCI,0)) as float) as pCategoryExplCI,
		cast(nUnexplainedCI as int) as nUnexplainedCI,
		cast((nUnexplainedCI/nullif(nExplicitCI,0)) as float) as pUnexplainedCI,
		cast(nExplicitII as int) as nExplicitII,
		cast(nIISubtype as int) as nIISubtype,
		cast((nIISubtype/nullif(nExplicitII,0)) as float) as pIISubtype,
		cast(nOnlyIIReuse as int) as nOnlyIIReuse,
		cast((nOnlyIIReuse/nullif(nExplicitII,0)) as float) as pOnlyIIReuse,
		cast(nExplainedII as int) as nExplainedII,
		cast((nExplainedII/nullif(nExplicitII,0)) as float) as pExplainedII,
		cast(nCategoryExplII as int) as nCategoryExplII,
		cast((nCategoryExplII/nullif(nExplicitII,0)) as float) as pCategoryExplII,
		cast(nUnexplainedII as int) as nUnexplainedII,
		cast((nUnexplainedII/nullif(nExplicitII,0)) as float) as pUnexplainedII
from summarizedMetrics m
join Project p
on m.ProjectId = p.ProjectId


GO
/****** Object:  View [dbo].[CCSubtypeChart]    Script Date: 7-10-2014 15:00:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
  CREATE view [dbo].[CCSubtypeChart] as
  select pm.Language,
		 pm.ProjectType,
		 pm.Name,
		 pm.nExplicitCC,
		 case when pm.nExplicitCC = 0 then '' else replicate('o', cast(log10(cast(pm.nExplicitCC as float)) as int)) end as SystemSize,
         pm.pCCSubtype as ST,
		 pm.pCCExreuseNoSubtype as 'EX-ST',
		 pm.pCCUsedOnlyInRe as 'INO',
		 pm.nCCSubtype as STCount,
		 pmtct.nCCSubtype as STCountNoTCT
  from [MasterThesis].[dbo].[ProjectMetrics] pm
  join [MasterThesis].[dbo].[ProjectMetricsNoTCT] pmtct
  on pm.ProjectId = pmtct.ProjectId
GO
/****** Object:  View [dbo].[DetailDataDirect]    Script Date: 7-10-2014 15:00:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE view [dbo].[DetailDataDirect] as 
with supers as (
	select distinct ProjectId, FromType, ToType, 1 as Value from dbo.Super
)
, externalReuse as (
	select distinct ProjectId, FromType, ToType, 1 as Value from dbo.ExternalReuse where Direct = 1
)
, internalReuse as (
	select distinct ProjectId, FromType, ToType, 1 as Value from dbo.InternalReuse where Direct = 1
)
, subtypes as (
	select distinct ProjectId, FromType, ToType, 1 as Value from dbo.Subtype where Direct = 1
), downcalls as (
	select distinct ProjectId, FromType, ToType, 1 as Value from dbo.Downcall where Direct = 1
), generics as (
	select distinct ProjectId, FromType, ToType, 1 as Value from dbo.Generic
)
SELECT tr.ProjectId, 
       RelationType, 
	   tr.FromType,
	   tr.ToType,
	  cast(SystemType as int) as SystemType, 
	  isnull( st.Value, 0) as Subtype,
	  isnull(i.Value, 0) as InternalReuse,
	  isnull( e.Value, 0) as ExternalReuse,
	  isnull(s.Value, 0) as Super,
	  isnull(d.Value, 0) as Downcall,
	  cast(Marker as int) as Marker, 
	  cast(Constants as int) as Constants,
	  isnull(g.Value, 0) as Generic
	  FROM [dbo].[TypeRelation] tr
	  LEFT JOIN supers s
	  on s.ProjectId = tr.ProjectId
	  and s.FromType = tr.FromType
	  and s.ToType = tr.ToType
	  LEFT JOIN internalReuse i
	  on i.ProjectId = tr.ProjectId
	  and i.FromType = tr.FromType
	  and i.ToType = tr.ToType
	  LEFT JOIN externalReuse e
	  on e.ProjectId = tr.ProjectId
	  and e.FromType = tr.FromType
	  and e.ToType = tr.ToType
	  LEFT JOIN subtypes st
	  on  st.ProjectId = tr.ProjectId
	  and st.FromType = tr.FromType
	  and st.ToType = tr.ToType
	  LEFT JOIN downcalls d
	  on  d.ProjectId = tr.ProjectId
	  and d.FromType = tr.FromType
	  and d.ToType = tr.ToType
	  LEFT JOIN generics g
	  on  g.ProjectId = tr.ProjectId
	  and g.FromType = tr.FromType
	  and g.ToType = tr.ToType
	  where DirectRelation = 1





GO
/****** Object:  View [dbo].[RelationAttributesDirect]    Script Date: 7-10-2014 15:00:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE view [dbo].[RelationAttributesDirect]
as
select rel.ProjectId, 
	   fromType.TypeLocation as FromType, 
	   toType.TypeLocation as ToType,
	   rel.DirectRelation as Explicit,
	   case when redundant.ProjectId is null then 0 else 1 end as Redundant,
	   case when rel.DirectRelation = 0 then 1 else 0 end as ImplicitKnown,
	   rel.SystemType as UserDefined,
	   rel.RelationType,
	   rel.Marker,
	   case when framework.ProjectId is null then 0 else 1 end as Framework,
	   case when category.ProjectId is null then 0 else 1 end as Category,
	   rel.Constants,
	   dd.Generic as Generic,
	   case when single.ProjectId is null then 0 else 1 end as Single,
	   dd.Downcall,
	   dd.Super as UpcallConstructor,
	   dd.InternalReuse as Upcall,
	   dd.ExternalReuse,
	   dd.Subtype
from dbo.TypeRelation rel
join dbo.[Type] fromType on fromType.TypeId = rel.FromType
join dbo.[Type] toType on toType.TypeId = rel.ToType
join dbo.DetailDataDirect dd
on rel.FromType = dd.FromType
and rel.ToType = dd.ToType
left join dbo.Redundant redundant
on rel.FromType = redundant.FromType
and rel.ToType = redundant.ToType
left join dbo.Framework framework
on rel.FromType = framework.FromType
and rel.ToType = framework.ToType
left join dbo.Category category
on rel.FromType = category.FromType
and rel.ToType = category.ToType
left join dbo.SingleRelation single
on rel.FromType = single.FromType
and rel.ToType = single.ToType


GO
/****** Object:  View [dbo].[BaseMetricsDirect]    Script Date: 7-10-2014 15:00:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE view [dbo].[BaseMetricsDirect] as
select a.ProjectId,
	a.FromType,
	a.ToType,
--nExplicitCC	Number of explicit userdefined cc edges
--- {(UserDefined) and (Explicit) and (CC)}
	case when UserDefined = 1 and Explicit = 1 and RelationType = 'CC' 
	then 1.0 else 0.0 end as nExplicitCC,
--nCCUsed	Explicit class edges for which some subtype use or reuse use was seen 
--- {(UserDefined) and (Explicit) and (CC) and (DirectExReuseField or IndirectExReuseField or DirectExReuseMethod 
---or IndirectExReuseMethod or DirectSubtype or IndirectSubtype or UpcallField or UpcallMethod)}
	case when UserDefined = 1 and Explicit = 1 and RelationType = 'CC'
	and (ExternalReuse = 1 or Subtype = 1 or Upcall = 1) 
	then 1.0 else 0.0 end as nCCUsed,
--nCCDC	Number of explicit CC edges that have Downcall use 
--- {(UserDefined) and (Explicit) and (CC) and (Downcall)}
	case when UserDefined = 1 and Explicit = 1 and RelationType = 'CC' and Downcall = 1 
	then 1.0 else 0.0 end as nCCDC,
--nCCSubtype	Used system CC edges for which subtype use was seen 
--- {(UserDefined) and (Explicit) and (CC) and (DirectSubtype or IndirectSubtype)}
	case when UserDefined = 1 and Explicit = 1 and RelationType = 'CC' and Subtype = 1
	then 1.0 else 0.0 end as nCCSubtype,
--nCCSubtype	Used system CC edges for which subtype use was seen 
--- {(UserDefined) and (Explicit) and (CC) and (DirectSubtype or IndirectSubtype)}
	case when UserDefined = 1 and Explicit = 1 and RelationType = 'CC' and (Subtype = 1 or Generic = 1 Or Framework =1 )
	then 1.0 else 0.0 end as nCCSuspectedSubtype,
--nCCExreuseNoSubtype	Used system CC edges for which no subtype use was seen, but external reuse use was seen 
--- {(UserDefined) and (Explicit) and (CC) and (DirectExReuseField or IndirectExReuseField or DirectExReuseMethod or IndirectExReuseMethod) 
--- and (not DirectSubtype) and (not IndirectSubtype)}
	case when UserDefined = 1 and Explicit = 1 and RelationType = 'CC' and ExternalReuse = 1 and Subtype = 0
	then 1.0 else 0.0 end as nCCExreuseNoSubtype,
--nCCUsedOnlyInRe	Used system CC edges for which only internal reuse was seen 
--- {(UserDefined) and (Explicit) and (CC) 
--and (not DirectExReuseField) and (notIndirectExReuseField) and (not DirectExReuseMethod) and (not IndirectExReuseMethod) a
--nd (not DirectSubtype) and (not IndirectSubtype) and (UpcallField or UpcallMethod)}
	case when UserDefined = 1 and Explicit = 1 and RelationType = 'CC' and ExternalReuse = 0 and Subtype = 0 and Upcall = 1
	then 1.0 else 0.0 end as nCCUsedOnlyInRe,
--nCCUnexplSuper	Explict system edges that have no use or explanation but super constructor calls 
--- {(UserDefined) and (Explicit) and (CC) and (not DirectExReuseField) and (not IndirectExReuseField) and (not DirectExReuseMethod) 
--and (not IndirectExReuseMethod) and (not DirectSubtype) and (not IndirectSubtype) and (not UpcallField) and (not UpcallMethod) 
--and (not Downcall) and (not ConstantsClass) and (not ConstantsInterface) and (not Marker) and (notFramework) and (not GenericUse) 
--and (UpcallConstructorSuper)}
	case when UserDefined = 1 and Explicit = 1 and RelationType = 'CC' and ExternalReuse = 0 and Subtype = 0 and Upcall = 0
	and Downcall = 0 and Constants = 0 and Marker = 0 and Framework = 0 and Generic = 0 and UpcallConstructor = 1
	then 1.0 else 0.0 end as nCCUnexplSuper,
--nCCUnexplCategory	Explict system edges that have no use or explanation (incl. super constructor calls) but has category use 
--- {(UserDefined) and (Explicit) and (CC) and (not DirectExReuseField) and (not IndirectExReuseField) and (not DirectExReuseMethod) 
--and (not IndirectExReuseMethod) and (not DirectSubtype) and (not IndirectSubtype) and (not UpcallField) and (not UpcallMethod) 
--and (not Downcall) and (not ConstantsClass) and (not ConstantsInterface) and (notMarker) and (not Framework) and (not GenericUse) 
--and (not UpcallConstructorSuper) and (Category)}
	case when UserDefined = 1 and Explicit = 1 and RelationType = 'CC' and ExternalReuse = 0 and Subtype = 0 and Upcall = 0
	and Downcall = 0 and Constants = 0 and Marker = 0 and Framework = 0 and Generic = 0 and UpcallConstructor = 0 and Category = 1
	then 1.0 else 0.0 end as nCCUnexplCategory,
--nCCUnknown	Explicit system class edges that no use or explanation is known (nCCUnused = nCCExplained+nCCUnknown) 
--- {(UserDefined) and (Explicit) and (CC) and (not DirectExReuseField) and (not IndirectExReuseField) and (not DirectExReuseMethod) 
---and (not IndirectExReuseMethod) and (not DirectSubtype) and (not IndirectSubtype) and (not UpcallField) 
---and (not UpcallMethod) and (not Downcall) and (not ConstantsClass) and (not ConstantsInterface) and (not Marker) 
---and (not Framework) and (not GenericUse) and (not UpcallConstructorSuper) and (not Category)}
	case when UserDefined = 1 and Explicit = 1 and RelationType = 'CC' and ExternalReuse = 0 and Subtype = 0 and Upcall = 0
	and Downcall = 0 and Constants = 0 and Marker = 0 and Framework = 0 and Generic = 0 and UpcallConstructor = 0 and Category = 0
	then 1.0 else 0.0 end as nCCUnknown,
--nExplicitCI	Explicit edges between user-defined classes and user-defined interfaces 
--- {(UserDefined) and (Explicit) and (CI)}
	case when UserDefined = 1 and Explicit = 1 and RelationType = 'CI' 
	then 1.0 else 0.0 end as nExplicitCI,
--nOnlyCISubtype	Edges between classes and interfaces for which subtype use was seen (the only use possible for such edges) 
--- {(UserDefined) and (Explicit) and (CI) and (DirectSubtype or IndirectSubtype)}
	case when UserDefined = 1 and Explicit = 1 and RelationType = 'CI' and Subtype = 1
	then 1.0 else 0.0 end as nOnlyCISubtype,
--nExplainedCI	Edges from class to interface with no subtype use seen, but with one of Framework, Generic, etc (not Category) 
--- {(UserDefined) and (Explicit) and (CI) and (not DirectSubtype) and (not IndirectSubtype) 
---and (Framework or GenericUse or Marker or ConstantsInterface or ConstantsClass)}
	case when UserDefined = 1 and Explicit = 1 and RelationType = 'CI' and Subtype = 0 
	and (Framework = 1 or Generic = 1 or Marker = 1 or Constants = 1)
	then 1.0 else 0.0 end as nExplainedCI,
--nCategoryExplCI	Edges for which no subtype use or other explanation was seen, but which have Category 
--- {(UserDefined) and (Explicit) and (CI) and (notDirectSubtype) and (not IndirectSubtype) and (not Framework) 
--- and (not GenericUse) and (not Marker) and (not ConstantsInterface) and (notConstantsClass) and (Category)}
	case when UserDefined = 1 and Explicit = 1 and RelationType = 'CI' and Subtype = 0 
	and Framework = 0 and Generic = 0 and Marker = 0 and Constants = 0 and Category = 1
	then 1.0 else 0.0 end as nCategoryExplCI,
--nUnexplainedCI	Edges from class to interface with no subtype use seen or explained (including Category) 
--- {(UserDefined) and (Explicit) and (CI) and (notDirectSubtype) and (not IndirectSubtype) and (not Framework) 
--- and (not GenericUse) and (not Marker) and (not ConstantsInterface) and (notConstantsClass) and (not Category)}
	case when UserDefined = 1 and Explicit = 1 and RelationType = 'CI' and Subtype = 0 
	and Framework = 0 and Generic = 0 and Marker = 0 and Constants = 0 and Category = 0
	then 1.0 else 0.0 end as nUnexplainedCI,
--nExplicitII	Explicit edges between user-defined interfaces 
--- {(UserDefined) and (Explicit) and (II)}
	case when UserDefined = 1 and Explicit = 1 and RelationType = 'II' 
	then 1.0 else 0.0 end as nExplicitII,
--nIISubtype	Edges between interfaces with at least subtype use 
--- {(UserDefined) and (Explicit) and (II) and (DirectSubtype or IndirectSubtype)}
	case when UserDefined = 1 and Explicit = 1 and RelationType = 'II' and Subtype = 1
	then 1.0 else 0.0 end as nIISubtype,
--nOnlyIIReuse	Edges between interfaces for which reuse was seen but not subtype 
--- {(UserDefined) and (Explicit) and (II) 
--- and (DirectExReuseField orIndirectExReuseField or DirectExReuseMethod or IndirectExReuseMethod) 
--- and (not DirectSubtype) and (not IndirectSubtype)}
	case when UserDefined = 1 and Explicit = 1 and RelationType = 'II' and Subtype = 0 and ExternalReuse = 1
	then 1.0 else 0.0 end as nOnlyIIReuse,
--nExplainedII	Unused edges between interface with some explanation (not category) 
--- {(UserDefined) and (Explicit) and (II) and (not DirectExReuseField) and (notIndirectExReuseField) 
--- and (not DirectExReuseMethod) and (not IndirectExReuseMethod) and (not DirectSubtype) and (not IndirectSubtype) 
--  and (Framework or GenericUse or Marker or ConstantsInterface or ConstantsClass)}
	case when UserDefined = 1 and Explicit = 1 and RelationType = 'II' and Subtype = 0 and ExternalReuse = 0
	and (Framework = 1 or Generic = 1 or Marker = 1 or Constants = 1)
	then 1.0 else 0.0 end as nExplainedII,
--nCategoryExplII	Edges for which no use or other explanation has been seen, but which have Category 
--- {(UserDefined) and (Explicit) and (II) and (notDirectExReuseField) and (not IndirectExReuseField) 
--- and (not DirectExReuseMethod) and (not IndirectExReuseMethod) and (not DirectSubtype) and (notIndirectSubtype) 
--- and (not Framework) and (not GenericUse) and (not Marker) and (not ConstantsInterface) and (not ConstantsClass) and (Category)}
	case when UserDefined = 1 and Explicit = 1 and RelationType = 'II' and Subtype = 0 and ExternalReuse = 0
	and Framework = 0 and Generic = 0 and Marker = 0 and Constants = 0 and Category = 1
	then 1.0 else 0.0 end as nCategoryExplII,
--nUnexplainedII	Edges between interfaces with no explanation (including Category)
--- {(UserDefined) and (Explicit) and (II) and (not DirectExReuseField) and (notIndirectExReuseField) 
--- and (not DirectExReuseMethod) and (not IndirectExReuseMethod) and (not DirectSubtype) and (not IndirectSubtype) 
--- and (notFramework) and (not GenericUse) and (not Marker) and (not ConstantsInterface) and (not ConstantsClass) and (not Category)}
	case when UserDefined = 1 and Explicit = 1 and RelationType = 'II' and ExternalReuse = 0 and Subtype = 0 
	and Framework = 0 and Generic = 0 and Marker = 0 and Constants = 0 and Category = 0
	then 1.0 else 0.0 end as nUnexplainedII
from dbo.RelationAttributesDirect a



GO
/****** Object:  View [dbo].[ProjectMetricsDirect]    Script Date: 7-10-2014 15:00:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE view [dbo].[ProjectMetricsDirect] as 
with summarizedMetrics as (
select  ProjectId,
		sum(nExplicitCC) as nExplicitCC,
		sum(nCCUsed) as nCCUsed,
		sum(nCCDC) as nCCDC,
		sum(nCCSubtype) as nCCSubtype,
		sum(nCCSuspectedSubtype) as nCCSuspectedSubtype,
		sum(nCCExreuseNoSubtype) as nCCExreuseNoSubtype,
		sum(nCCUsedOnlyInRe) as nCCUsedOnlyInRe,
		sum(nCCUnexplSuper) as nCCUnexplSuper,
		sum(nCCUnexplCategory) as nCCUnexplCategory,
		sum(nCCUnknown) as nCCUnknown,
		sum(nExplicitCI) as nExplicitCI,
		sum(nOnlyCISubtype) as nOnlyCISubtype,
		sum(nExplainedCI) as nExplainedCI,
		sum(nCategoryExplCI) as nCategoryExplCI,
		sum(nUnexplainedCI) as nUnexplainedCI,
		sum(nExplicitII) as nExplicitII,
		sum(nIISubtype) as nIISubtype,
		sum(nOnlyIIReuse) as nOnlyIIReuse,
		sum(nExplainedII) as nExplainedII,
		sum(nCategoryExplII) as nCategoryExplII,
		sum(nUnexplainedII) as nUnexplainedII
		from BaseMetricsDirect m
		group by ProjectId)
select  m.ProjectId,
		p.Language,
		p.ProjectType,
		p.Name,
		p.LinesOfCode,
		cast(nExplicitCC as int) as nExplicitCC,
		cast(nCCUsed as int) as nCCUsed,
		cast((nCCUsed/nullif(nExplicitCC,0)) as float) as pCCUsed,
		cast(nCCDC as int) as nCCDC,
		cast((nCCDC/nullif(nExplicitCC,0)) as float) as pCCDC,
		cast(nCCSubtype as int) as nCCSubtype,
		cast((nCCSubtype/nullif(nCCUsed,0)) as float) as pCCSubtype,
		cast(nCCSuspectedSubtype as int) as nCCSuspectedSubtype,
		cast((nCCSuspectedSubtype/nullif(nCCUsed,0)) as float) as pCCSuspectedSubtype,
		cast(nCCExreuseNoSubtype as int) as nCCExreuseNoSubtype,
		cast((nCCExreuseNoSubtype/nullif(nCCUsed,0)) as float) as pCCExreuseNoSubtype,
		cast(nCCUsedOnlyInRe as int) as nCCUsedOnlyInRe,
		cast((nCCUsedOnlyInRe/nullif(nCCUsed,0)) as float) as pCCUsedOnlyInRe,
		cast(nCCUnexplSuper as int) as nCCUnexplSuper,
		cast((nCCUnexplSuper/nullif(nExplicitCC,0)) as float) as pCCUnexplSuper,
		cast(nCCUnexplCategory as int) as nCCUnexplCategory,
		cast((nCCUnexplCategory/nullif(nExplicitCC,0)) as float) as pCCUnexplCategory,
		cast(nCCUnknown as int) as nCCUnknown,
		cast((nCCUnknown/nullif(nExplicitCC,0)) as float) as pCCUnknown,
		cast(nExplicitCI as int) as nExplicitCI,
		cast(nOnlyCISubtype as int) as nOnlyCISubtype,
		cast((nOnlyCISubtype/nullif(nExplicitCI,0)) as float) as pOnlyCISubtype,
		cast(nExplainedCI as int) as nExplainedCI,
		cast((nExplainedCI/nullif(nExplicitCI,0)) as float) as pExplainedCI,
		cast(nCategoryExplCI as int) as nCategoryExplCI,
		cast((nCategoryExplCI/nullif(nExplicitCI,0)) as float) as pCategoryExplCI,
		cast(nUnexplainedCI as int) as nUnexplainedCI,
		cast((nUnexplainedCI/nullif(nExplicitCI,0)) as float) as pUnexplainedCI,
		cast(nExplicitII as int) as nExplicitII,
		cast(nIISubtype as int) as nIISubtype,
		cast((nIISubtype/nullif(nExplicitII,0)) as float) as pIISubtype,
		cast(nOnlyIIReuse as int) as nOnlyIIReuse,
		cast((nOnlyIIReuse/nullif(nExplicitII,0)) as float) as pOnlyIIReuse,
		cast(nExplainedII as int) as nExplainedII,
		cast((nExplainedII/nullif(nExplicitII,0)) as float) as pExplainedII,
		cast(nCategoryExplII as int) as nCategoryExplII,
		cast((nCategoryExplII/nullif(nExplicitII,0)) as float) as pCategoryExplII,
		cast(nUnexplainedII as int) as nUnexplainedII,
		cast((nUnexplainedII/nullif(nExplicitII,0)) as float) as pUnexplainedII
from summarizedMetrics m
join Project p
on m.ProjectId = p.ProjectId

GO
/****** Object:  View [dbo].[SubtypeInfo]    Script Date: 7-10-2014 15:00:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE view [dbo].[SubtypeInfo]
as
select pm.ProjectId,
       pm.Language,
	   pm.ProjectType,
	   pm.Name,
	   pm.LinesOfCode,
	   pm.nExplicitCC,
	   case when pm.nExplicitCC = 0 then '' else replicate('o', cast(log10(cast(pm.nExplicitCC as float)) as int)) end as SystemSize,
	   pm.nCCSubtype as AllSubtype,
	   pmd.nCCSubtype as DirectSubtype,
	   pmtct.nccSubtype as NoThisChangingTypeSubtype
from ProjectMetrics pm
join ProjectMetricsDirect pmd
on pmd.ProjectId = pm.ProjectId
join ProjectMetricsNoTCT pmtct
on pmtct.ProjectId = pm.ProjectId
GO
/****** Object:  View [dbo].[LanguageAndTypeComparison]    Script Date: 7-10-2014 15:00:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE view [dbo].[LanguageAndTypeComparison] as
select Language, ProjectType,
	   count(*) as Systems,
       sum(LinesOfCode) as LinesOfCodeTotal, 
	   avg(LinesOfCode) as LinesOfCodeAverage,
	   stdev(LinesOfCode) as LinesOfCodeStdDev,
       sum(nExplicitCC) as CCEdgesTotal, 
	   avg(nExplicitCC) as CCEdgesAverage,
	   stdev(nExplicitCC) as CCEdgesStdDev,
       sum(nExplicitCI) as CIEdgesTotal, 
	   avg(nExplicitCI) as CIEdgesAverage,
	   stdev(nExplicitCI) as CIEdgesStdDev,
       sum(nExplicitII) as IIEdgesTotal, 
	   avg(nExplicitII) as IIEdgesAverage,
	   stdev(nExplicitII) as IIEdgesStdDev
from ProjectMetrics
group by Language, ProjectType

GO
/****** Object:  View [dbo].[InheritanceUseData]    Script Date: 7-10-2014 15:00:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view [dbo].[InheritanceUseData]
as
SELECT
       pm.[ProjectType] [Type]
      ,pm.[Language]
      ,pm.[Name]
      ,pm.[nExplicitCC]
      ,pm.[nCCUsed]
      ,pm.[pCCUsed]
      ,pmd.[nCCDC]
      ,pmd.[pCCDC]
      ,pm.[nCCSubtype]
      ,pm.[pCCSubtype]
      ,pm.[nCCExreuseNoSubtype]
      ,pm.[pCCExreuseNoSubtype]
      ,pm.[nCCUsedOnlyInRe]
      ,pm.[pCCUsedOnlyInRe]
      ,pm.[nCCUnexplSuper]
      ,pm.[pCCUnexplSuper]
      ,pm.[nCCUnexplCategory]
      ,pm.[pCCUnexplCategory]
      ,pm.[nCCUnknown]
      ,pm.[pCCUnknown]
      ,pm.[nExplicitCI]
      ,pm.[nOnlyCISubtype]
      ,pm.[pOnlyCISubtype]
      ,pm.[nExplainedCI]
      ,pm.[pExplainedCI]
      ,pm.[nCategoryExplCI]
      ,pm.[pCategoryExplCI]
      ,pm.[nUnexplainedCI]
      ,pm.[pUnexplainedCI]
      ,pm.[nExplicitII]
      ,pm.[nIISubtype]
      ,pm.[pIISubtype]
      ,pm.[nOnlyIIReuse]
      ,pm.[pOnlyIIReuse]
      ,pm.[nExplainedII]
      ,pm.[pExplainedII]
      ,pm.[nCategoryExplII]
      ,pm.[pCategoryExplII]
      ,pm.[nUnexplainedII]
      ,pm.[pUnexplainedII]
  FROM [MasterThesis].[dbo].[ProjectMetrics] pm
  join [MasterThesis].[dbo].[ProjectMetricsDirect] pmd
  on pm.projectid = pmd.projectid
GO
/****** Object:  View [dbo].[ConstantsInfo]    Script Date: 7-10-2014 15:00:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE view [dbo].[ConstantsInfo]
as
with constants as (
	select ProjectId, 
	       RelationType, 
	       count(*) as ConstantsNumber
	from RelationAttributes attr
	where Explicit = 1 and UserDefined = 1 and Framework = 0 
	  and Constants = 1 and Generic = 0 and Downcall = 0 
	 and UpcallConstructor = 0 and Upcall = 0 and ExternalReuse = 0 and Subtype = 0 and Marker = 0
	group by ProjectId, RelationType
), allRelations as (
	select ProjectId, 
	       RelationType, 
	       count(*) as ConstantsNumber
	from RelationAttributes attr
	where Explicit = 1 and UserDefined = 1
	group by ProjectId, RelationType
)
select p.Language, 
       p.ProjectType, 
	   p.Name, 
	   c.RelationType, 
	   c.ConstantsNumber as ConstantsCount, 
	   r.ConstantsNumber as AllRelationCount
from Project p
join constants c
on c.ProjectId = p.ProjectId
join allRelations r
on r.ProjectId = p.ProjectId
where c.RelationType = r.RelationType


GO
/****** Object:  View [dbo].[MarkerInfo]    Script Date: 7-10-2014 15:00:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view [dbo].[MarkerInfo]
as
with constants as (
	select ProjectId, 
	       RelationType, 
	       count(*) as ConstantsNumber
	from RelationAttributes attr
	where Explicit = 1 and UserDefined = 1 and Framework = 0 
	  and Constants = 0 and Generic = 0 and Downcall = 0 
	 and UpcallConstructor = 0 and Upcall = 0 and ExternalReuse = 0 and Subtype = 0 and Marker = 1
	group by ProjectId, RelationType
), allRelations as (
	select ProjectId, 
	       RelationType, 
	       count(*) as ConstantsNumber
	from RelationAttributes attr
	where Explicit = 1 and UserDefined = 1
	group by ProjectId, RelationType
)
select p.Language, 
       p.ProjectType, 
	   p.Name, 
	   c.RelationType, 
	   c.ConstantsNumber as ConstantsCount, 
	   r.ConstantsNumber as AllRelationCount
from Project p
join constants c
on c.ProjectId = p.ProjectId
join allRelations r
on r.ProjectId = p.ProjectId
where c.RelationType = r.RelationType


GO
/****** Object:  View [dbo].[FrameworkGenericInfo]    Script Date: 7-10-2014 15:00:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view [dbo].[FrameworkGenericInfo]
as
with constants as (
	select ProjectId, 
	       RelationType, 
	       count(*) as ConstantsNumber
	from RelationAttributes attr
	where Explicit = 1 and UserDefined = 1 and (Framework = 1  or Generic = 1)
	  and Constants = 0 and Downcall = 0 
	 and UpcallConstructor = 0 and Upcall = 0 and ExternalReuse = 0 and Subtype = 0 and Marker = 0
	group by ProjectId, RelationType
), allRelations as (
	select ProjectId, 
	       RelationType, 
	       count(*) as ConstantsNumber
	from RelationAttributes attr
	where Explicit = 1 and UserDefined = 1
	group by ProjectId, RelationType
)
select p.Language, 
       p.ProjectType, 
	   p.Name, 
	   c.RelationType, 
	   c.ConstantsNumber as ConstantsCount, 
	   r.ConstantsNumber as AllRelationCount
from Project p
join constants c
on c.ProjectId = p.ProjectId
join allRelations r
on r.ProjectId = p.ProjectId
where c.RelationType = r.RelationType


GO
/****** Object:  View [dbo].[CCDowncallChart]    Script Date: 7-10-2014 15:00:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
  CREATE view [dbo].[CCDowncallChart] as
  select pm.Language,
         pm.ProjectType,
		 pm.Name,
		 pm.nExplicitCC,
		 case when pm.nExplicitCC = 0 then '' else replicate('o', cast(log10(cast(pm.nExplicitCC as float)) as int)) end as SystemSize,
         pm.pCCDC as IndirectDowncallProportion,
         pmd.pCCDC as DirectDowncallProportion
  from [MasterThesis].[dbo].[ProjectMetrics] pm
  join [MasterThesis].[dbo].[ProjectMetricsDirect] pmd
  on pm.ProjectId = pmd.ProjectId
GO
/****** Object:  View [dbo].[DynamicUsage]    Script Date: 7-10-2014 15:00:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE view [dbo].[DynamicUsage]
as
select p.Name,
       p.ProjectId,
	   p.Language,
	   p.ProjectType,
	   d.DynamicOccurrences,
	   d.StaticOccurrences,
	   d.DynamicOccurrences / cast(d.StaticOccurrences + d.DynamicOccurrences as float) as pDynamic
from dbo.DynamicUse d
join dbo.Project p
on d.ProjectId = p.ProjectId 

GO
/****** Object:  View [dbo].[SubtypeKind]    Script Date: 7-10-2014 15:00:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE view [dbo].[SubtypeKind] as
select top 100 percent pr.Language, pr.ProjectType, st.SubtypeKind, count(*) as Count
from dbo.Subtype st
join dbo.Project pr
on st.ProjectId = pr.ProjectId
where Omitted = 0
group by pr.Language, pr.ProjectType, st.SubtypeKind
order by Language, ProjectType, SubtypeKind

GO
/****** Object:  View [dbo].[SubtypeSources]    Script Date: 7-10-2014 15:00:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO





--Assignment
--Cast
--Conditional
--conditional()
--ContravariantTypeArgument
--CovariantTypeArgument
--Foreach
--foreachStatement()
--Parameter
--parameterPassed()
--Return
--returned()
--SidewaysCast
--sidewaysCast()
--ThisChangingType
--thisChangingType()
--typeCasted()
--varAssigned()
--VariableInitializer
--varInitialized()

CREATE view [dbo].[SubtypeSources] as
with Casts as (
	select distinct FromType, ToType from Subtype where SubtypeKind in ('Cast', 'typeCasted()')
),SidewaysCast as (
	select distinct FromType, ToType from Subtype where SubtypeKind in ('SidewaysCast', 'sidewaysCast()')
),Foreach as (
	select distinct FromType, ToType from Subtype where SubtypeKind in ('Foreach', 'foreachStatement()')
),Conditional as (
	select distinct FromType, ToType from Subtype where SubtypeKind in ('Conditional', 'conditional()')
),Returns as (
	select distinct FromType, ToType from Subtype where SubtypeKind in ('Return', 'returned()')
),ThisChangingType as (
	select distinct FromType, ToType from Subtype where SubtypeKind in ('ThisChangingType', 'thisChangingType()') and Omitted = 0
),Assignment as (
	select distinct FromType, ToType from Subtype where SubtypeKind in ('Assignment', 'varAssigned()')
),Initializer as (
 	select distinct FromType, ToType from Subtype where SubtypeKind in ('varInitialized()', 'VariableInitializer')
),Parameter as (
	select distinct FromType, ToType from Subtype where SubtypeKind in ('Parameter', 'parameterPassed()')
), Variance as (
	select distinct FromType, ToType from Subtype where SubtypeKind in ('CovariantTypeArgument', 'ContravariantTypeArgument')
), AllSubtype as (
	select distinct FromType, ToType from Subtype
), Results as (
select p.Language,
       t.FromType,
       t.ToType,
	   case when exists (select top 1 1 from Casts where FromType = t.FromType and ToType = t.ToType) then 1 else 0 end as Casts,
	   case when exists (select top 1 1 from Foreach where FromType = t.FromType and ToType = t.ToType) then 1 else 0 end as Foreach,
	   case when exists (select top 1 1 from Returns where FromType = t.FromType and ToType = t.ToType) then 1 else 0 end as Returns,
	   case when exists (select top 1 1 from SidewaysCast where FromType = t.FromType and ToType = t.ToType) then 1 else 0 end as SidewaysCast,
	   case when exists (select top 1 1 from Conditional where FromType = t.FromType and ToType = t.ToType) then 1 else 0 end as Conditional,
	   case when exists (select top 1 1 from ThisChangingType where FromType = t.FromType and ToType = t.ToType) then 1 else 0 end as ThisChangingType,
	   case when exists (select top 1 1 from Assignment where FromType = t.FromType and ToType = t.ToType) then 1 else 0 end as Assignment,
	   case when exists (select top 1 1 from Initializer where FromType = t.FromType and ToType = t.ToType) then 1 else 0 end as Initializer,
	   case when exists (select top 1 1 from Parameter where FromType = t.FromType and ToType = t.ToType) then 1 else 0 end as Parameter,
	   case when exists (select top 1 1 from Variance where FromType = t.FromType and ToType = t.ToType) then 1 else 0 end as Variance
from dbo.TypeRelation t
join dbo.Project p
on t.ProjectId = p.ProjectId
where DirectRelation = 1and relationType = 'CC' and SystemType = 1 and exists (select top 1 1 from AllSubtype where FromType = t.FromType and ToType = t.ToType)) 
select Language,
       avg(convert(float, Casts)) as Casts,
	   avg(convert(float, Foreach)) as Foreach,
	   avg(convert(float, Returns)) as Returns,
	   avg(convert(float, ThisChangingType)) as ThisChangingType,
	   avg(convert(float, Assignment)) as Assignment,
	   avg(convert(float, Initializer)) as Initializer,
	   avg(convert(float, Conditional)) as Conditional,
	   avg(convert(float, SidewaysCast)) as SidewaysCast,
	   avg(convert(float, Parameter)) as Parameter,
	   avg(convert(float, Variance)) as GenericVariance
from Results
group by Language


GO
/****** Object:  View [dbo].[SubtypeSourcesByProject]    Script Date: 7-10-2014 15:00:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE view [dbo].[SubtypeSourcesByProject] as
with Casts as (
	select distinct FromType, ToType from Subtype where SubtypeKind in ('Cast', 'typeCasted()')
),SidewaysCast as (
	select distinct FromType, ToType from Subtype where SubtypeKind in ('SidewaysCast', 'sidewaysCast()')
),Foreach as (
	select distinct FromType, ToType from Subtype where SubtypeKind in ('Foreach', 'foreachStatement()')
),Conditional as (
	select distinct FromType, ToType from Subtype where SubtypeKind in ('Conditional', 'conditional()')
),Returns as (
	select distinct FromType, ToType from Subtype where SubtypeKind in ('Return', 'returned()')
),ThisChangingType as (
	select distinct FromType, ToType from Subtype where SubtypeKind in ('ThisChangingType', 'thisChangingType()') and Omitted = 0
),Assignment as (
	select distinct FromType, ToType from Subtype where SubtypeKind in ('Assignment', 'varAssigned()')
),Initializer as (
 	select distinct FromType, ToType from Subtype where SubtypeKind in ('varInitialized()', 'VariableInitializer')
),Parameter as (
	select distinct FromType, ToType from Subtype where SubtypeKind in ('Parameter', 'parameterPassed()')
), Variance as (
	select distinct FromType, ToType from Subtype where SubtypeKind in ('CovariantTypeArgument', 'ContravariantTypeArgument')
), AllSubtype as (
	select distinct FromType, ToType from Subtype
), Results as (
select p.ProjectId,
       t.FromType,
       t.ToType,
	   case when exists (select top 1 1 from Casts where FromType = t.FromType and ToType = t.ToType) then 1 else 0 end as Casts,
	   case when exists (select top 1 1 from Foreach where FromType = t.FromType and ToType = t.ToType) then 1 else 0 end as Foreach,
	   case when exists (select top 1 1 from Returns where FromType = t.FromType and ToType = t.ToType) then 1 else 0 end as Returns,
	   case when exists (select top 1 1 from SidewaysCast where FromType = t.FromType and ToType = t.ToType) then 1 else 0 end as SidewaysCast,
	   case when exists (select top 1 1 from Conditional where FromType = t.FromType and ToType = t.ToType) then 1 else 0 end as Conditional,
	   case when exists (select top 1 1 from ThisChangingType where FromType = t.FromType and ToType = t.ToType) then 1 else 0 end as ThisChangingType,
	   case when exists (select top 1 1 from Assignment where FromType = t.FromType and ToType = t.ToType) then 1 else 0 end as Assignment,
	   case when exists (select top 1 1 from Initializer where FromType = t.FromType and ToType = t.ToType) then 1 else 0 end as Initializer,
	   case when exists (select top 1 1 from Parameter where FromType = t.FromType and ToType = t.ToType) then 1 else 0 end as Parameter,
	   case when exists (select top 1 1 from Variance where FromType = t.FromType and ToType = t.ToType) then 1 else 0 end as Variance
from dbo.TypeRelation t
join dbo.Project p
on t.ProjectId = p.ProjectId
where DirectRelation = 1and relationType = 'CC' and SystemType = 1 and exists (select top 1 1 from AllSubtype where FromType = t.FromType and ToType = t.ToType)) 
select p.Language,
       p.Name,
	   d.NonVarCount,
	   d.VarCount,
       avg(convert(float, Casts)) as Casts,
	   avg(convert(float, Foreach)) as Foreach,
	   avg(convert(float, Returns)) as Returns,
	   avg(convert(float, ThisChangingType)) as ThisChangingType,
	   avg(convert(float, Assignment)) as Assignment,
	   avg(convert(float, Initializer)) as Initializer,
	   avg(convert(float, Conditional)) as Conditional,
	   avg(convert(float, SidewaysCast)) as SidewaysCast,
	   avg(convert(float, Parameter)) as Parameter,
	   avg(convert(float, Variance)) as GenericVariance
from Results r
join Project p
on r.ProjectId = p.ProjectId
join DynamicUse d
on d.ProjectId = p.ProjectId
group by p.Language, r.ProjectId, d.NonVarCount, d.VarCount, p.Name
GO
/****** Object:  View [dbo].[Summary]    Script Date: 7-10-2014 15:00:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




CREATE view [dbo].[Summary] as 
with supers as (
	select distinct ProjectId, FromType, ToType, 1 as Value from dbo.Super
)
, externalReuse as (
	select distinct ProjectId, FromType, ToType, 1 as Value from dbo.ExternalReuse
)
, internalReuse as (
	select distinct ProjectId, FromType, ToType, 1 as Value from dbo.InternalReuse
)
, subtypes as (
	select distinct ProjectId, FromType, ToType, 1 as Value from dbo.Subtype
), downcalls as (
	select distinct ProjectId, FromType, ToType, 1 as Value from dbo.Downcall
)
SELECT tr.ProjectId, p.Language, p.Name, RelationType, 
  count(*) as Count,
  Sum(cast(SystemType as int)) as SystemType,
  isnull(sum(st.Value * cast(SystemType as int)), 0) as Subtype,
  isnull(sum(d.Value * cast(SystemType as int)), 0) as Downcall, 
  isnull(sum(i.Value * cast(SystemType as int)), 0) as InternalReuse,
  isnull(sum(e.Value * cast(SystemType as int)), 0) as ExternalReuse,
  isnull(sum(s.Value * cast(SystemType as int)), 0) as Super, 
  sum(cast(Marker as int) * cast(SystemType as int)) as Marker, 
  sum(cast(Constants as int) * cast(SystemType as int)) as Constants
  FROM [dbo].[TypeRelation] tr
  INNER JOIN dbo.Project p
  on p.ProjectId = tr.ProjectId
  LEFT JOIN supers s
  on s.ProjectId = tr.ProjectId
  and s.FromType = tr.FromType
  and s.ToType = tr.ToType
  LEFT JOIN internalReuse i
  on i.ProjectId = tr.ProjectId
  and i.FromType = tr.FromType
  and i.ToType = tr.ToType
  LEFT JOIN externalReuse e
  on e.ProjectId = tr.ProjectId
  and e.FromType = tr.FromType
  and e.ToType = tr.ToType
	LEFT JOIN subtypes st
	on  st.ProjectId = tr.ProjectId
	and st.FromType = tr.FromType
	and st.ToType = tr.ToType
	  LEFT JOIN downcalls d
	  on  d.ProjectId = tr.ProjectId
	  and d.FromType = tr.FromType
	  and d.ToType = tr.ToType
  where DirectRelation = 1
  group by tr.ProjectId, RelationType, p.Language, p.Name




GO
/****** Object:  View [dbo].[SystemSizeInfo]    Script Date: 7-10-2014 15:00:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE view [dbo].[SystemSizeInfo]
as
with systemTypesInRelations as (
	select ProjectId, FromType as TypeId from dbo.[TypeRelation] union select ProjectId, ToType from dbo.[TypeRelation] where SystemType = 1
), systemTypesWithoutInheritance as (
	select ProjectId, TypeId from dbo.[Type] where IsOwnCode = 1
	except select ProjectId, TypeId from systemTypesInRelations
), groupedSystemTypesWithoutInheritance as (
	select ProjectId, count(distinct TypeId) as Count
	from systemTypesWithoutInheritance group by ProjectId
), systemTypesWithInheritance as (
	select ProjectId, TypeId from dbo.[Type] where IsOwnCode = 1
	intersect select ProjectId, TypeId from systemTypesInRelations
), groupedSystemTypesWithInheritance as (
	select ProjectId, count(distinct TypeId) as Count
	from systemTypesWithInheritance group by ProjectId
), totalSystemTypes as (
	select ProjectId, count(TypeId) as Count
	from dbo.[Type]
	where IsOwnCode = 1
	group by ProjectId
)
select pr.ProjectId,
	   pr.Language,
	   pr.ProjectType,
	   pr.Name,
	   pr.LinesOfCode,
	   pr.LinesOfComment,
	   totalSystem.Count as TotalSystemTypeCount,
	   withInheritance.Count as SystemTypeCountParticipatingInInheritance,
	   withoutInheritance.Count as SystemTypeCountNotParticipatingInInheritance
from dbo.Project pr
join groupedSystemTypesWithInheritance withInheritance
on withInheritance.ProjectId = pr.ProjectId
join groupedSystemTypesWithoutInheritance withoutInheritance
on withoutInheritance.ProjectId = pr.ProjectId
join totalSystemTypes totalSystem
on totalSystem.ProjectId = pr.ProjectId

GO
/****** Object:  Index [IX_Downcall]    Script Date: 7-10-2014 15:00:03 ******/
CREATE NONCLUSTERED INDEX [IX_Downcall] ON [dbo].[Downcall]
(
	[ProjectId] ASC,
	[FromType] ASC,
	[ToType] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [IX_ExternalReuse]    Script Date: 7-10-2014 15:00:03 ******/
CREATE NONCLUSTERED INDEX [IX_ExternalReuse] ON [dbo].[ExternalReuse]
(
	[ProjectId] ASC,
	[FromType] ASC,
	[ToType] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [IX_FromTypeEX]    Script Date: 7-10-2014 15:00:03 ******/
CREATE NONCLUSTERED INDEX [IX_FromTypeEX] ON [dbo].[ExternalReuse]
(
	[FromType] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [IX_FromType]    Script Date: 7-10-2014 15:00:03 ******/
CREATE NONCLUSTERED INDEX [IX_FromType] ON [dbo].[InternalReuse]
(
	[FromType] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [IX_InternalReuse]    Script Date: 7-10-2014 15:00:03 ******/
CREATE NONCLUSTERED INDEX [IX_InternalReuse] ON [dbo].[InternalReuse]
(
	[ProjectId] ASC,
	[FromType] ASC,
	[ToType] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [IX_STFromType]    Script Date: 7-10-2014 15:00:03 ******/
CREATE NONCLUSTERED INDEX [IX_STFromType] ON [dbo].[Subtype]
(
	[FromType] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [IX_Subtype]    Script Date: 7-10-2014 15:00:03 ******/
CREATE NONCLUSTERED INDEX [IX_Subtype] ON [dbo].[Subtype]
(
	[ProjectId] ASC,
	[FromType] ASC,
	[ToType] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_SubtypeKind]    Script Date: 7-10-2014 15:00:03 ******/
CREATE NONCLUSTERED INDEX [IX_SubtypeKind] ON [dbo].[Subtype]
(
	[SubtypeKind] ASC
)
INCLUDE ( 	[ProjectId],
	[FromType],
	[ToType]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [IX_SubtypeToType]    Script Date: 7-10-2014 15:00:03 ******/
CREATE NONCLUSTERED INDEX [IX_SubtypeToType] ON [dbo].[Subtype]
(
	[ToType] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [IX_Super]    Script Date: 7-10-2014 15:00:03 ******/
CREATE NONCLUSTERED INDEX [IX_Super] ON [dbo].[Super]
(
	[ProjectId] ASC,
	[FromType] ASC,
	[ToType] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [IX_SystemTypes]    Script Date: 7-10-2014 15:00:03 ******/
CREATE NONCLUSTERED INDEX [IX_SystemTypes] ON [dbo].[Type]
(
	[IsOwnCode] ASC
)
INCLUDE ( 	[TypeId],
	[ProjectId]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [IX_Type]    Script Date: 7-10-2014 15:00:03 ******/
CREATE NONCLUSTERED INDEX [IX_Type] ON [dbo].[Type]
(
	[ProjectId] ASC,
	[IsOwnCode] ASC
)
INCLUDE ( 	[TypeId]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_TypeRelation>]    Script Date: 7-10-2014 15:00:03 ******/
CREATE NONCLUSTERED INDEX [IX_TypeRelation>] ON [dbo].[TypeRelation]
(
	[DirectRelation] ASC
)
INCLUDE ( 	[ProjectId],
	[FromType],
	[ToType],
	[RelationType],
	[Marker],
	[Constants],
	[SystemType]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [IX_TypeRelationProject]    Script Date: 7-10-2014 15:00:03 ******/
CREATE NONCLUSTERED INDEX [IX_TypeRelationProject] ON [dbo].[TypeRelation]
(
	[ProjectId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Downcall] ADD  CONSTRAINT [DF_Downcall_Direct]  DEFAULT ((1)) FOR [Direct]
GO
ALTER TABLE [dbo].[DynamicUse] ADD  CONSTRAINT [DF_DynamicUse_VarCount]  DEFAULT ((0)) FOR [VarCount]
GO
ALTER TABLE [dbo].[DynamicUse] ADD  CONSTRAINT [DF_DynamicUse_NonVarCount]  DEFAULT ((0)) FOR [NonVarCount]
GO
ALTER TABLE [dbo].[Project] ADD  CONSTRAINT [DF__Project__Created__5441852A]  DEFAULT (getdate()) FOR [CreatedDate]
GO
ALTER TABLE [dbo].[Project] ADD  DEFAULT ('Open Source') FOR [ProjectType]
GO
ALTER TABLE [dbo].[Subtype] ADD  CONSTRAINT [DF_Subtype_Omitted]  DEFAULT ((0)) FOR [Omitted]
GO
ALTER TABLE [dbo].[Downcall]  WITH NOCHECK ADD  CONSTRAINT [FK__Downcall__FromTy__1AD3FDA4] FOREIGN KEY([FromType])
REFERENCES [dbo].[Type] ([TypeId])
GO
ALTER TABLE [dbo].[Downcall] CHECK CONSTRAINT [FK__Downcall__FromTy__1AD3FDA4]
GO
ALTER TABLE [dbo].[Downcall]  WITH NOCHECK ADD  CONSTRAINT [FK__Downcall__Projec__1BC821DD] FOREIGN KEY([ProjectId])
REFERENCES [dbo].[Project] ([ProjectId])
GO
ALTER TABLE [dbo].[Downcall] CHECK CONSTRAINT [FK__Downcall__Projec__1BC821DD]
GO
ALTER TABLE [dbo].[Downcall]  WITH NOCHECK ADD  CONSTRAINT [FK__Downcall__ToType__1CBC4616] FOREIGN KEY([ToType])
REFERENCES [dbo].[Type] ([TypeId])
GO
ALTER TABLE [dbo].[Downcall] CHECK CONSTRAINT [FK__Downcall__ToType__1CBC4616]
GO
ALTER TABLE [dbo].[ExternalReuse]  WITH NOCHECK ADD  CONSTRAINT [FK__ExternalR__FromT__05D8E0BE] FOREIGN KEY([FromType])
REFERENCES [dbo].[Type] ([TypeId])
GO
ALTER TABLE [dbo].[ExternalReuse] CHECK CONSTRAINT [FK__ExternalR__FromT__05D8E0BE]
GO
ALTER TABLE [dbo].[ExternalReuse]  WITH NOCHECK ADD  CONSTRAINT [FK__ExternalR__Proje__06CD04F7] FOREIGN KEY([ProjectId])
REFERENCES [dbo].[Project] ([ProjectId])
GO
ALTER TABLE [dbo].[ExternalReuse] CHECK CONSTRAINT [FK__ExternalR__Proje__06CD04F7]
GO
ALTER TABLE [dbo].[ExternalReuse]  WITH NOCHECK ADD  CONSTRAINT [FK__ExternalR__ToTyp__07C12930] FOREIGN KEY([ToType])
REFERENCES [dbo].[Type] ([TypeId])
GO
ALTER TABLE [dbo].[ExternalReuse] CHECK CONSTRAINT [FK__ExternalR__ToTyp__07C12930]
GO
ALTER TABLE [dbo].[Generic]  WITH NOCHECK ADD  CONSTRAINT [FK_GenericProjectId] FOREIGN KEY([ProjectId])
REFERENCES [dbo].[Project] ([ProjectId])
GO
ALTER TABLE [dbo].[Generic] CHECK CONSTRAINT [FK_GenericProjectId]
GO
ALTER TABLE [dbo].[InternalReuse]  WITH NOCHECK ADD  CONSTRAINT [FK__InternalR__FromT__01142BA1] FOREIGN KEY([FromType])
REFERENCES [dbo].[Type] ([TypeId])
GO
ALTER TABLE [dbo].[InternalReuse] CHECK CONSTRAINT [FK__InternalR__FromT__01142BA1]
GO
ALTER TABLE [dbo].[InternalReuse]  WITH NOCHECK ADD  CONSTRAINT [FK__InternalR__Proje__02084FDA] FOREIGN KEY([ProjectId])
REFERENCES [dbo].[Project] ([ProjectId])
GO
ALTER TABLE [dbo].[InternalReuse] CHECK CONSTRAINT [FK__InternalR__Proje__02084FDA]
GO
ALTER TABLE [dbo].[InternalReuse]  WITH NOCHECK ADD  CONSTRAINT [FK__InternalR__ToTyp__02FC7413] FOREIGN KEY([ToType])
REFERENCES [dbo].[Type] ([TypeId])
GO
ALTER TABLE [dbo].[InternalReuse] CHECK CONSTRAINT [FK__InternalR__ToTyp__02FC7413]
GO
ALTER TABLE [dbo].[Subtype]  WITH NOCHECK ADD  CONSTRAINT [FK_SubtypeFromTypeId] FOREIGN KEY([FromType])
REFERENCES [dbo].[Type] ([TypeId])
GO
ALTER TABLE [dbo].[Subtype] CHECK CONSTRAINT [FK_SubtypeFromTypeId]
GO
ALTER TABLE [dbo].[Subtype]  WITH NOCHECK ADD  CONSTRAINT [FK_SubtypeProjectId] FOREIGN KEY([ProjectId])
REFERENCES [dbo].[Project] ([ProjectId])
GO
ALTER TABLE [dbo].[Subtype] CHECK CONSTRAINT [FK_SubtypeProjectId]
GO
ALTER TABLE [dbo].[Subtype]  WITH NOCHECK ADD  CONSTRAINT [FK_SubtypeToTypeId] FOREIGN KEY([ToType])
REFERENCES [dbo].[Type] ([TypeId])
GO
ALTER TABLE [dbo].[Subtype] CHECK CONSTRAINT [FK_SubtypeToTypeId]
GO
ALTER TABLE [dbo].[Super]  WITH NOCHECK ADD  CONSTRAINT [FK__Super__FromType__72C60C4A] FOREIGN KEY([FromType])
REFERENCES [dbo].[Type] ([TypeId])
GO
ALTER TABLE [dbo].[Super] CHECK CONSTRAINT [FK__Super__FromType__72C60C4A]
GO
ALTER TABLE [dbo].[Super]  WITH NOCHECK ADD  CONSTRAINT [FK__Super__ProjectId__73BA3083] FOREIGN KEY([ProjectId])
REFERENCES [dbo].[Project] ([ProjectId])
GO
ALTER TABLE [dbo].[Super] CHECK CONSTRAINT [FK__Super__ProjectId__73BA3083]
GO
ALTER TABLE [dbo].[Super]  WITH NOCHECK ADD  CONSTRAINT [FK__Super__ToType__74AE54BC] FOREIGN KEY([ToType])
REFERENCES [dbo].[Type] ([TypeId])
GO
ALTER TABLE [dbo].[Super] CHECK CONSTRAINT [FK__Super__ToType__74AE54BC]
GO
ALTER TABLE [dbo].[Type]  WITH NOCHECK ADD  CONSTRAINT [FK__Type__ProjectId__571DF1D5] FOREIGN KEY([ProjectId])
REFERENCES [dbo].[Project] ([ProjectId])
GO
ALTER TABLE [dbo].[Type] CHECK CONSTRAINT [FK__Type__ProjectId__571DF1D5]
GO
ALTER TABLE [dbo].[TypeRelation]  WITH NOCHECK ADD  CONSTRAINT [FK__TypeRelat__FromT__5AEE82B9] FOREIGN KEY([FromType])
REFERENCES [dbo].[Type] ([TypeId])
GO
ALTER TABLE [dbo].[TypeRelation] CHECK CONSTRAINT [FK__TypeRelat__FromT__5AEE82B9]
GO
ALTER TABLE [dbo].[TypeRelation]  WITH NOCHECK ADD  CONSTRAINT [FK__TypeRelat__Proje__59FA5E80] FOREIGN KEY([ProjectId])
REFERENCES [dbo].[Project] ([ProjectId])
GO
ALTER TABLE [dbo].[TypeRelation] CHECK CONSTRAINT [FK__TypeRelat__Proje__59FA5E80]
GO
ALTER TABLE [dbo].[TypeRelation]  WITH NOCHECK ADD  CONSTRAINT [FK__TypeRelat__ToType__5AEE82B9] FOREIGN KEY([ToType])
REFERENCES [dbo].[Type] ([TypeId])
GO
ALTER TABLE [dbo].[TypeRelation] CHECK CONSTRAINT [FK__TypeRelat__ToType__5AEE82B9]
GO
ALTER TABLE [dbo].[TypeRelation]  WITH NOCHECK ADD CHECK  (([RelationType]='II' OR [RelationType]='CI' OR [RelationType]='CC'))
GO
ALTER TABLE [dbo].[TypeRelation]  WITH NOCHECK ADD CHECK  (([RelationType]='II' OR [RelationType]='CI' OR [RelationType]='CC'))
GO
USE [master]
GO
ALTER DATABASE [MasterThesis] SET  READ_WRITE 
GO
