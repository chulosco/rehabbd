USE [master]
GO
/****** Object:  Database [RP]    Script Date: 4/30/2017 12:37:57 PM ******/
CREATE DATABASE [RP]
 CONTAINMENT = NONE
 ON  PRIMARY 
( NAME = N'RP', FILENAME = N'c:\Program Files\Microsoft SQL Server\MSSQL11.SQLEXPRESS\MSSQL\DATA\RP.mdf' , SIZE = 3072KB , MAXSIZE = UNLIMITED, FILEGROWTH = 1024KB )
 LOG ON 
( NAME = N'RP_log', FILENAME = N'c:\Program Files\Microsoft SQL Server\MSSQL11.SQLEXPRESS\MSSQL\DATA\RP_log.ldf' , SIZE = 1024KB , MAXSIZE = 2048GB , FILEGROWTH = 10%)
GO
ALTER DATABASE [RP] SET COMPATIBILITY_LEVEL = 110
GO
IF (1 = FULLTEXTSERVICEPROPERTY('IsFullTextInstalled'))
begin
EXEC [RP].[dbo].[sp_fulltext_database] @action = 'enable'
end
GO
ALTER DATABASE [RP] SET ANSI_NULL_DEFAULT OFF 
GO
ALTER DATABASE [RP] SET ANSI_NULLS OFF 
GO
ALTER DATABASE [RP] SET ANSI_PADDING OFF 
GO
ALTER DATABASE [RP] SET ANSI_WARNINGS OFF 
GO
ALTER DATABASE [RP] SET ARITHABORT OFF 
GO
ALTER DATABASE [RP] SET AUTO_CLOSE OFF 
GO
ALTER DATABASE [RP] SET AUTO_CREATE_STATISTICS ON 
GO
ALTER DATABASE [RP] SET AUTO_SHRINK OFF 
GO
ALTER DATABASE [RP] SET AUTO_UPDATE_STATISTICS ON 
GO
ALTER DATABASE [RP] SET CURSOR_CLOSE_ON_COMMIT OFF 
GO
ALTER DATABASE [RP] SET CURSOR_DEFAULT  GLOBAL 
GO
ALTER DATABASE [RP] SET CONCAT_NULL_YIELDS_NULL OFF 
GO
ALTER DATABASE [RP] SET NUMERIC_ROUNDABORT OFF 
GO
ALTER DATABASE [RP] SET QUOTED_IDENTIFIER OFF 
GO
ALTER DATABASE [RP] SET RECURSIVE_TRIGGERS OFF 
GO
ALTER DATABASE [RP] SET  DISABLE_BROKER 
GO
ALTER DATABASE [RP] SET AUTO_UPDATE_STATISTICS_ASYNC OFF 
GO
ALTER DATABASE [RP] SET DATE_CORRELATION_OPTIMIZATION OFF 
GO
ALTER DATABASE [RP] SET TRUSTWORTHY OFF 
GO
ALTER DATABASE [RP] SET ALLOW_SNAPSHOT_ISOLATION OFF 
GO
ALTER DATABASE [RP] SET PARAMETERIZATION SIMPLE 
GO
ALTER DATABASE [RP] SET READ_COMMITTED_SNAPSHOT OFF 
GO
ALTER DATABASE [RP] SET HONOR_BROKER_PRIORITY OFF 
GO
ALTER DATABASE [RP] SET RECOVERY SIMPLE 
GO
ALTER DATABASE [RP] SET  MULTI_USER 
GO
ALTER DATABASE [RP] SET PAGE_VERIFY CHECKSUM  
GO
ALTER DATABASE [RP] SET DB_CHAINING OFF 
GO
ALTER DATABASE [RP] SET FILESTREAM( NON_TRANSACTED_ACCESS = OFF ) 
GO
ALTER DATABASE [RP] SET TARGET_RECOVERY_TIME = 0 SECONDS 
GO
USE [RP]
GO
/****** Object:  StoredProcedure [dbo].[spUPCtp2_ActualizarDiagnostico]    Script Date: 4/30/2017 12:37:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[spUPCtp2_ActualizarDiagnostico]
	@fecha varchar(10),
	@diagnostico varchar(1500),
	@periodo int,
	@tratamiento varchar(1500),
	@nroSesiones int,
	@observacion varchar(1000),
	@pacienteId int,
	@especialistaId int
AS
BEGIN
	DECLARE @FECHADATE DATETIME
	SET @FECHADATE=  CONVERT(DATETIME,@fecha, 120)


	insert into Diagnostico (fecha, diagnostico, periodo, tratamiento, Nro_Sesiones,observacion ,pacienteId, Especialistaid)
	values (@FECHADATE, @diagnostico, @periodo, @tratamiento, @nroSesiones,@observacion, @pacienteId, @especialistaId)
END

GO
/****** Object:  StoredProcedure [dbo].[spUPCtp2_ActualizarSesionXFechaYHora]    Script Date: 4/30/2017 12:37:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spUPCtp2_ActualizarSesionXFechaYHora] 
(
	@Pacienteid varchar(10),
	@Terapistaid varchar(10),
	@Fecha varchar(10),
	@hora varchar(10),
	@Nro_sesion int,
	@observacion varchar(10)
	
)
AS	
	Declare @Fecha_Hora datetime 
	Declare @flag_Ins_Upd int
	Declare @Diagnosticoid int

	SET @Fecha_Hora = CONVERT(DATETIME,@Fecha, 120) + CONVERT(DATETIME,@hora, 120)
	--SET @Fecha_Hora = '2017-04-26 09:00'

	SELECT @flag_Ins_Upd = count(*)
	from Cronograma_TerapistaDetalle 
	where Hora_Inicio = CONVERT(DATETIME,@hora,120)
	and Cronograma_Terapistaid in (	select id
									from Cronograma_Terapista 
									where Terapistaid in (	select id		
															from Terapista 
															where id = @Terapistaid))


	SELECT @flag_Ins_Upd as 'flag_ins_upd'
IF @flag_Ins_Upd > 0  --update
BEGIN
	update Cronograma_TerapistaDetalle set estado = 'R'
	where  Cronograma_Terapistaid in (	select id
									from Cronograma_Terapista 
									where Cronograma_Terapistaid in (	select id		
																		from Terapista 
																		where id = @Terapistaid))
	and Hora_Inicio = @Fecha_Hora
															
	update	Ficha_Evolucion set Hora = @Fecha_Hora, Terapistaid = @Terapistaid, observacion = @observacion 
	where	numero_sesion = @Nro_sesion
	and		Diagnosticoid in (	select Di.id
								from Diagnostico Di
								where Di.Pacienteid in (	select Pa.id 
															from Paciente Pa
															where Pa.id = @Pacienteid)) 
END
ELSE 
	
	 -- Insert

	 select @Diagnosticoid = (	select	top 1 Di.id
								from	Diagnostico Di
								where	Di.Pacienteid in (	select Pa.id 
															from Paciente Pa
															where Pa.id = @Pacienteid)
								order by Di.FechaIniTerapia desc)

		INSERT INTO [dbo].[Ficha_Evolucion]
			   ([numero_sesion]
			   ,[observacion]
			   ,[Fecha]
			   ,[Hora]
			   ,[Terapistaid]
			   ,[Diagnosticoid])
		 VALUES
			   (@Nro_sesion,
				@observacion, 
				@Fecha_Hora,
				@Fecha_Hora,
				@Terapistaid, 
				@Diagnosticoid)

	update	Ficha_Evolucion set Hora = @Fecha_Hora, Terapistaid = @Terapistaid 
		where	numero_sesion = @Nro_sesion
		and		Diagnosticoid in (	select Di.id
									from Diagnostico Di
									where Di.Pacienteid in (	select Pa.id 
																from Paciente Pa
																where Pa.id = @Pacienteid))

RETURN



SELECT * FROM [Ficha_Evolucion]


GO
/****** Object:  StoredProcedure [dbo].[spUPCtp2_DatosDiagnostico]    Script Date: 4/30/2017 12:37:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[spUPCtp2_DatosDiagnostico] 
(
	@DNIPaciente nvarchar(20)	
)
AS	
	select TOP 1 Di.Nro_Sesiones, Di.Periodo, Di.observacion, Di.diagnostico as diagnostico, Es.Nombre +' '+ Es.Ape_Paterno + ' ' + Es.Ape_Materno AS NombreEspecialista , Te.Nombre + ' ' + Te.Ape_Paterno + ' ' +  Te.Ape_Materno AS NombreTerapista
	from Diagnostico Di, Especialista Es, Terapista Te, Paciente Pa,  Ficha_Evolucion FE
	where Pa.Doc_Identidad = @DNIPaciente
	and   Pa.id = Di.Pacienteid
	order by Di.Fecha desc

RETURN 

GO
/****** Object:  StoredProcedure [dbo].[spUPCtp2_DatosPaciente]    Script Date: 4/30/2017 12:37:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[spUPCtp2_DatosPaciente] 
	@nroDoc nvarchar(20)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    SELECT * FROM Paciente where Doc_Identidad = @nroDoc;
END

GO
/****** Object:  StoredProcedure [dbo].[spUPCtp2_DIagnosticosPaciente]    Script Date: 4/30/2017 12:37:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spUPCtp2_DIagnosticosPaciente]
@pacienteId int
AS
SELECT	D.id, 
		D.Fecha, 
		D.Diagnostico, 
		D.Periodo, 
		D.FechaIniTerapia, 
		D.Tratamiento, 
		D.Nro_Sesiones, D.observacion, 
CONCAT(E.Nombre,' ',E.Ape_Paterno,' ', E.Ape_Materno) 'especialista' FROM Diagnostico D, Especialista E
WHERE D.PacienteId = @pacienteId
AND D.Especialistaid = E.id
GO
/****** Object:  StoredProcedure [dbo].[spUPCtp2_HorasXFechaTerapista]    Script Date: 4/30/2017 12:37:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[spUPCtp2_HorasXFechaTerapista] 
(

	@Fecha datetime
)
AS	
select	Distinct(SubString(convert(varchar, convert(time,Hora_Inicio)),1,5))  AS HorasDisponiblesTerapistas
from	Cronograma_TerapistaDetalle 
where	Fecha = @Fecha
and		Estado = 'D'
order by  SubString(convert(varchar, convert(time,Hora_Inicio)),1,5)  asc

RETURN











GO
/****** Object:  StoredProcedure [dbo].[spUPCtp2_InsFichaEvolucion]    Script Date: 4/30/2017 12:37:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[spUPCtp2_InsFichaEvolucion]
(
@nroSesion int,
@fecha datetime,
@hora datetime,
@terapistaId int,
@idDiagnostico int
)
as
INSERT INTO Ficha_Evolucion
(numero_sesion,Fecha, Hora, Terapistaid, Diagnosticoid)
VALUES (@nroSesion, @Fecha,@hora, @terapistaId, @idDiagnostico)

GO
/****** Object:  StoredProcedure [dbo].[spUPCtp2_ProfesionalXFechaYHora]    Script Date: 4/30/2017 12:37:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- TipoProfesional:
-- 1 --> Especialista
-- 2 --> Terapista 


CREATE PROCEDURE [dbo].[spUPCtp2_ProfesionalXFechaYHora] 
(

	@Fecha varchar(10),
	@hora varchar(10),
	@TipoProfesional int
)
AS	
   DECLARE     @Fecha_Hora datetime
    
     SET @Fecha_Hora = CONVERT(DATETIME,@Fecha, 120) + CONVERT(DATETIME,@hora, 120)

IF @TipoProfesional = 1  --Especialista
	select	id, Doc_Identidad, Nombre, Ape_Paterno, Ape_Materno  
	from	Especialista 
	where	id in (	select Especialistaid 
					from Cronograma_Especialista 
					where id in (	select Cronograma_Especialistaid
									from Cronograma_EspecialistaDetalle 
									where Hora_Inicio = @Fecha_Hora
									and Estado = 'D'))
	order by Nombre asc


ELSE
	select	id, Doc_Identidad, Nombre, Ape_Paterno, Ape_Materno  
	from	Terapista 
	where	id in (	select Terapistaid 
					from Cronograma_Terapista
					where Terapistaid in (	select Cronograma_Terapistaid
									from Cronograma_TerapistaDetalle 
									where Hora_Inicio = @Fecha_Hora
									and Estado = 'D'))
	order by Nombre asc


RETURN 




GO
/****** Object:  StoredProcedure [dbo].[spUPCtp2_SesionesProgramadasXPaciente]    Script Date: 4/30/2017 12:37:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[spUPCtp2_SesionesProgramadasXPaciente] 
(
	@DocPaciente varchar(20)
	
)
AS	

select FE.id, FE.Fecha, FE.Hora, FE.numero_sesion,  Es.Nombre +' '+ Es.Ape_Paterno AS Especialista, Te.Nombre +' '+ Te.Ape_Paterno AS Terapista, FE.observacion
from  Ficha_Evolucion FE, Terapista Te, Especialista Es, Paciente Pa,Diagnostico Di
where	Pa.Doc_Identidad = @DocPaciente
and		Pa.id = Di.Pacienteid
and		Di.id = FE.Diagnosticoid
and		FE.Terapistaid = Te.id 
and     Di.Especialistaid = Es.id


RETURN









GO
/****** Object:  StoredProcedure [dbo].[spUPCtp2_SesionPacienteXFechaHora]    Script Date: 4/30/2017 12:37:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[spUPCtp2_SesionPacienteXFechaHora] 
(
	@DocPaciente varchar(20),
	@Fecha varchar(10),
	@hora varchar(10)
)
AS	

DECLARE     @Fecha_Hora datetime
    
SET @Fecha_Hora = CONVERT(DATETIME,@Fecha, 120) + CONVERT(DATETIME,@hora, 120)


select FE.id, FE.Fecha, FE.Hora, FE.numero_sesion,  Es.Nombre +' '+ Es.Ape_Paterno AS Especialista, Te.Nombre +' '+ Te.Ape_Paterno AS Terapista, FE.observacion
from  Ficha_Evolucion FE, Terapista Te, Especialista Es, Paciente Pa,Diagnostico Di
where	Pa.Doc_Identidad = @DocPaciente
and		FE.Hora = @Fecha_Hora
and		Pa.id = Di.Pacienteid
and		Di.id = FE.Diagnosticoid
and		FE.Terapistaid = Te.id 
and     Di.Especialistaid = Es.id


RETURN

GO
/****** Object:  Table [dbo].[Alta]    Script Date: 4/30/2017 12:37:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Alta](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[alimentacion] [varchar](1000) NULL,
	[Higiene] [varchar](1000) NULL,
	[Ejercicio] [varchar](1000) NULL,
	[observacion] [varchar](1000) NULL,
	[Diagnosticoid] [int] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Cita]    Script Date: 4/30/2017 12:37:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Cita](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[Fecha_CIta] [int] NULL,
	[Hora_Cita] [int] NULL,
	[observacion] [varchar](1000) NULL,
	[Cronograma_Profesionalid] [int] NOT NULL,
	[Profesionalid] [int] NOT NULL,
	[Pacienteid] [int] NOT NULL,
	[Plan_Servicioid] [int] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Cronograma_Especialista]    Script Date: 4/30/2017 12:37:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Cronograma_Especialista](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[Fecha] [datetime] NULL,
	[Nro_Sesiones] [int] NULL,
	[estado] [varchar](2) NULL,
	[observacion] [varchar](1000) NULL,
	[Especialistaid] [int] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Cronograma_EspecialistaDetalle]    Script Date: 4/30/2017 12:37:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Cronograma_EspecialistaDetalle](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[Fecha] [datetime] NULL,
	[Hora_Inicio] [datetime] NULL,
	[estado] [varchar](2) NULL,
	[observacion] [varchar](1000) NULL,
	[Cronograma_Especialistaid] [int] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Cronograma_Servicio]    Script Date: 4/30/2017 12:37:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Cronograma_Servicio](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[Fecha] [datetime] NULL,
	[Fecha_Inicio] [datetime] NULL,
	[Hora_Fin] [datetime] NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[Cronograma_Servicio_Equipo]    Script Date: 4/30/2017 12:37:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Cronograma_Servicio_Equipo](
	[Cronograma_Servicioid] [int] NOT NULL,
	[Equipoid] [int] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Cronograma_Servicioid] ASC,
	[Equipoid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[Cronograma_Servicio_Sala]    Script Date: 4/30/2017 12:37:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Cronograma_Servicio_Sala](
	[Cronograma_Servicioid] [int] NOT NULL,
	[Salaid] [int] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Cronograma_Servicioid] ASC,
	[Salaid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[Cronograma_Terapista]    Script Date: 4/30/2017 12:37:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Cronograma_Terapista](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[Fecha] [datetime] NULL,
	[Nro_Sesiones] [int] NULL,
	[estado] [varchar](2) NULL,
	[observacion] [varchar](1000) NULL,
	[Terapistaid] [int] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Cronograma_TerapistaDetalle]    Script Date: 4/30/2017 12:37:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Cronograma_TerapistaDetalle](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[Fecha] [datetime] NULL,
	[Hora_Inicio] [datetime] NULL,
	[estado] [varchar](2) NULL,
	[observacion] [varchar](1000) NULL,
	[Cronograma_Terapistaid] [int] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Diagnostico]    Script Date: 4/30/2017 12:37:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Diagnostico](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[Fecha] [datetime] NULL,
	[Diagnostico] [varchar](1500) NULL,
	[Periodo] [int] NULL,
	[FechaIniTerapia] [datetime] NULL,
	[Tratamiento] [varchar](1500) NULL,
	[Nro_Sesiones] [int] NULL,
	[observacion] [varchar](1000) NULL,
	[Pacienteid] [int] NOT NULL,
	[Especialistaid] [int] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Equipo]    Script Date: 4/30/2017 12:37:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Equipo](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[Nro_Serie] [int] NULL,
	[Nombre] [varchar](50) NULL,
	[Marca] [varchar](50) NULL,
	[Modelo] [varchar](50) NULL,
	[observacion] [varchar](1000) NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Especialista]    Script Date: 4/30/2017 12:37:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Especialista](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[Doc_Identidad] [int] NULL,
	[Nombre] [varchar](50) NULL,
	[Ape_Paterno] [varchar](50) NULL,
	[Ape_Materno] [varchar](50) NULL,
	[Sexo] [varchar](2) NULL,
	[Telefono] [int] NULL,
	[Direccion] [varchar](150) NULL,
	[Nro_Colegiatura] [int] NULL,
	[TipoEspecialidadid] [int] NOT NULL,
	[TipoDocumentoid] [int] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Ficha_Evolucion]    Script Date: 4/30/2017 12:37:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Ficha_Evolucion](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[numero_sesion] [int] NOT NULL,
	[observacion] [varchar](1000) NULL,
	[Fecha] [datetime] NULL,
	[Hora] [datetime] NULL,
	[Terapistaid] [int] NOT NULL,
	[Diagnosticoid] [int] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Historia_Clinica]    Script Date: 4/30/2017 12:37:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Historia_Clinica](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[Fecha_creacion] [datetime] NULL,
	[Fecha_Actualizacion] [datetime] NULL,
	[Historia] [varchar](1500) NULL,
	[Especialidad] [varchar](50) NULL,
	[Pacienteid] [int] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Paciente]    Script Date: 4/30/2017 12:37:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Paciente](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[Doc_Identidad] [varchar](20) NULL,
	[Nombre] [varchar](50) NULL,
	[Ape_Materno] [varchar](50) NULL,
	[Ape_Paterno] [varchar](50) NULL,
	[Fecha_Nacimiento] [datetime] NULL,
	[Edad] [int] NULL,
	[Sexo] [varchar](2) NULL,
	[Telefono] [int] NULL,
	[Direccion] [varchar](150) NULL,
	[Grupo_Sanguineo] [varchar](10) NULL,
	[TipoDocumentoid] [int] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Sala]    Script Date: 4/30/2017 12:37:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Sala](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[Nro] [int] NULL,
	[Nombre] [varchar](50) NULL,
	[Ubicacion] [varchar](50) NULL,
	[Especialidad] [varchar](50) NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Terapista]    Script Date: 4/30/2017 12:37:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Terapista](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[Doc_Identidad] [int] NULL,
	[Nombre] [varchar](50) NULL,
	[Ape_Paterno] [varchar](50) NULL,
	[Ape_Materno] [varchar](50) NULL,
	[Sexo] [varchar](2) NULL,
	[Telefono] [int] NULL,
	[Direccion] [varchar](150) NULL,
	[Nro_Colegiatura] [int] NULL,
	[TipoDocumentoid] [int] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[TipoDocumento]    Script Date: 4/30/2017 12:37:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[TipoDocumento](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[Documento] [varchar](50) NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[TipoEspecialidad]    Script Date: 4/30/2017 12:37:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[TipoEspecialidad](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[Especialidad] [varchar](50) NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
ALTER TABLE [dbo].[Alta]  WITH CHECK ADD  CONSTRAINT [AltaXDiagnostico] FOREIGN KEY([Diagnosticoid])
REFERENCES [dbo].[Diagnostico] ([id])
GO
ALTER TABLE [dbo].[Alta] CHECK CONSTRAINT [AltaXDiagnostico]
GO
ALTER TABLE [dbo].[Cronograma_Especialista]  WITH CHECK ADD  CONSTRAINT [EspecialistaXCronograma] FOREIGN KEY([Especialistaid])
REFERENCES [dbo].[Especialista] ([id])
GO
ALTER TABLE [dbo].[Cronograma_Especialista] CHECK CONSTRAINT [EspecialistaXCronograma]
GO
ALTER TABLE [dbo].[Cronograma_EspecialistaDetalle]  WITH CHECK ADD  CONSTRAINT [CronogramaDetalleXCronogramaEspecialista] FOREIGN KEY([Cronograma_Especialistaid])
REFERENCES [dbo].[Cronograma_Especialista] ([id])
GO
ALTER TABLE [dbo].[Cronograma_EspecialistaDetalle] CHECK CONSTRAINT [CronogramaDetalleXCronogramaEspecialista]
GO
ALTER TABLE [dbo].[Cronograma_Servicio_Equipo]  WITH CHECK ADD  CONSTRAINT [FKCronograma210242] FOREIGN KEY([Equipoid])
REFERENCES [dbo].[Equipo] ([id])
GO
ALTER TABLE [dbo].[Cronograma_Servicio_Equipo] CHECK CONSTRAINT [FKCronograma210242]
GO
ALTER TABLE [dbo].[Cronograma_Servicio_Equipo]  WITH CHECK ADD  CONSTRAINT [FKCronograma472083] FOREIGN KEY([Cronograma_Servicioid])
REFERENCES [dbo].[Cronograma_Servicio] ([id])
GO
ALTER TABLE [dbo].[Cronograma_Servicio_Equipo] CHECK CONSTRAINT [FKCronograma472083]
GO
ALTER TABLE [dbo].[Cronograma_Servicio_Sala]  WITH CHECK ADD  CONSTRAINT [0..* 1..*] FOREIGN KEY([Cronograma_Servicioid])
REFERENCES [dbo].[Cronograma_Servicio] ([id])
GO
ALTER TABLE [dbo].[Cronograma_Servicio_Sala] CHECK CONSTRAINT [0..* 1..*]
GO
ALTER TABLE [dbo].[Cronograma_Servicio_Sala]  WITH CHECK ADD  CONSTRAINT [FKCronograma801448] FOREIGN KEY([Salaid])
REFERENCES [dbo].[Sala] ([id])
GO
ALTER TABLE [dbo].[Cronograma_Servicio_Sala] CHECK CONSTRAINT [FKCronograma801448]
GO
ALTER TABLE [dbo].[Cronograma_Terapista]  WITH CHECK ADD  CONSTRAINT [TerapistaXCronograma] FOREIGN KEY([Terapistaid])
REFERENCES [dbo].[Terapista] ([id])
GO
ALTER TABLE [dbo].[Cronograma_Terapista] CHECK CONSTRAINT [TerapistaXCronograma]
GO
ALTER TABLE [dbo].[Cronograma_TerapistaDetalle]  WITH CHECK ADD  CONSTRAINT [CronoTerapistaDetalleXCronoTerapista] FOREIGN KEY([Cronograma_Terapistaid])
REFERENCES [dbo].[Cronograma_Terapista] ([id])
GO
ALTER TABLE [dbo].[Cronograma_TerapistaDetalle] CHECK CONSTRAINT [CronoTerapistaDetalleXCronoTerapista]
GO
ALTER TABLE [dbo].[Diagnostico]  WITH CHECK ADD  CONSTRAINT [DiagnosticosXPaciente] FOREIGN KEY([Pacienteid])
REFERENCES [dbo].[Paciente] ([id])
GO
ALTER TABLE [dbo].[Diagnostico] CHECK CONSTRAINT [DiagnosticosXPaciente]
GO
ALTER TABLE [dbo].[Diagnostico]  WITH CHECK ADD  CONSTRAINT [ProfesionalXDiagnostico] FOREIGN KEY([Especialistaid])
REFERENCES [dbo].[Especialista] ([id])
GO
ALTER TABLE [dbo].[Diagnostico] CHECK CONSTRAINT [ProfesionalXDiagnostico]
GO
ALTER TABLE [dbo].[Especialista]  WITH CHECK ADD  CONSTRAINT [EspecilidadXEspecialista] FOREIGN KEY([TipoEspecialidadid])
REFERENCES [dbo].[TipoEspecialidad] ([id])
GO
ALTER TABLE [dbo].[Especialista] CHECK CONSTRAINT [EspecilidadXEspecialista]
GO
ALTER TABLE [dbo].[Especialista]  WITH CHECK ADD  CONSTRAINT [ProfesionalXTipoDocumento] FOREIGN KEY([TipoDocumentoid])
REFERENCES [dbo].[TipoDocumento] ([id])
GO
ALTER TABLE [dbo].[Especialista] CHECK CONSTRAINT [ProfesionalXTipoDocumento]
GO
ALTER TABLE [dbo].[Ficha_Evolucion]  WITH CHECK ADD  CONSTRAINT [FichaEvolucionXDiagnostico] FOREIGN KEY([Diagnosticoid])
REFERENCES [dbo].[Diagnostico] ([id])
GO
ALTER TABLE [dbo].[Ficha_Evolucion] CHECK CONSTRAINT [FichaEvolucionXDiagnostico]
GO
ALTER TABLE [dbo].[Ficha_Evolucion]  WITH CHECK ADD  CONSTRAINT [TerapistaXFichaEvolucion] FOREIGN KEY([Terapistaid])
REFERENCES [dbo].[Terapista] ([id])
GO
ALTER TABLE [dbo].[Ficha_Evolucion] CHECK CONSTRAINT [TerapistaXFichaEvolucion]
GO
ALTER TABLE [dbo].[Historia_Clinica]  WITH CHECK ADD  CONSTRAINT [HistoriaXPaciente] FOREIGN KEY([Pacienteid])
REFERENCES [dbo].[Paciente] ([id])
GO
ALTER TABLE [dbo].[Historia_Clinica] CHECK CONSTRAINT [HistoriaXPaciente]
GO
ALTER TABLE [dbo].[Paciente]  WITH CHECK ADD  CONSTRAINT [PacienteXTipoDocumento] FOREIGN KEY([TipoDocumentoid])
REFERENCES [dbo].[TipoDocumento] ([id])
GO
ALTER TABLE [dbo].[Paciente] CHECK CONSTRAINT [PacienteXTipoDocumento]
GO
ALTER TABLE [dbo].[Terapista]  WITH CHECK ADD  CONSTRAINT [TipoDocumentoXTerapista] FOREIGN KEY([TipoDocumentoid])
REFERENCES [dbo].[TipoDocumento] ([id])
GO
ALTER TABLE [dbo].[Terapista] CHECK CONSTRAINT [TipoDocumentoXTerapista]
GO
USE [master]
GO
ALTER DATABASE [RP] SET  READ_WRITE 
GO
