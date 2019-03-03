set ANSI_NULLS ON
set QUOTED_IDENTIFIER ON
go

IF  EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[dbo].[sp_SendMail]') AND OBJECTPROPERTY(id,N'IsProcedure') = 1)
	DROP PROCEDURE [dbo].[sp_SendMail]
GO

---------------------------------------------------------------------------------------------------
-- Módulo que utiliza : 
---------------------------------------------------------------------------------------------------
-- Descrição	: Envia Emails
-- Autor		: Sérgio
-- Data de Criação	: 25/07/2005
-- Input		: 
-- 		@From 		varchar(100) - Origem
-- 		@To 		varchar(100) - Destino
-- 		@Subject 	varchar(100) - Assunto
-- 		@Body 		varchar(8000) - Corpo do email
--		@AddAttachment varchar(8000) = Caminho para anexo,
--		@SmtpServer varchar(8000) = SERVIDOR SMTP		Ex. 'smtp.voxage.com.br',
--		@SmtpPort	varchar(8000) = PORTA SERVIDOR SMTP Ex. '25'
--		@smtpauthenticate INT = 0
--									smtpauthenticate: Specifies the mechanism used when authenticating to an SMTP service over the network. Possible values are:
--									- cdoAnonymous	, value 0. Do not authenticate.
--									- cdoBasic		, value 1. Use basic clear-text authentication. When using this option you have to provide the user name and password through the sendusername and sendpassword fields.
--									- cdoNTLM		, value 2. The current process security context is used to authenticate with the service.
--
--
-- Output		: < Não possui>
---------------------------------------------------------------------------------------------------
-- Exemplo:
/*

--Do not authenticate
	EXEC sp_SendMail
		@From			= "EquipeBD@ABC.com.br", 
		@To				= 'Sergio@ABC.com.br;teste@ABC.com', 
		@Subject		= 'Teste123', 
		@Body			= 'Teste 234',
		@AddAttachment	= NULL,
		@SmtpServer		= 'smtp.ABC.com.br',
		@SmtpPort		= '25',
		@smtpauthenticate = '0' --Do not authenticate

--Use basic clear-text authentication
	EXEC sp_SendMail
		@From			= "EquipeBD@ABC.com.br", 
		@To				= 'Sergio@ABC.com.br;teste@ABC.com', 
		@Subject		= 'Teste123', 
		@Body			= 'Teste 234',
		@AddAttachment	= NULL,
		@SmtpServer		= 'smtp.ABC.com.br',
		@SmtpPort		= '25',
		@smtpauthenticate = '1', --Use basic clear-text authentication
		@sendusername	= 'USER',
		@sendpassword	= 'SENHA'
*/ 
---------------------------------------------------------------------------------------------------
-- Histórico de Alterações
-- Data		: 30/08/2006
-- Autor	: Sérgio
-- Descrição: Incluido parametro AddAttachment, @SmtpServer, @SmtpPort
---------------------------------------------------------------------------------------------------
-- Data		: 03/11/2006
-- Autor	: Sérgio
-- Descrição: Incluido opção de autenticação
---------------------------------------------------------------------------------------------------
CREATE PROCEDURE [dbo].[sp_SendMail]
(
	@From varchar(100) , 
	@To varchar(8000) , 
	@Subject varchar(500)		 = " ", 
	@Body varchar(8000)			 = " ",
	@AddAttachment varchar(8000) = NULL,
	@SmtpServer varchar(8000)	 = 'smtp.ABC.com.br',
	@SmtpPort	varchar(8000)	 = '25',
	@smtpauthenticate VARCHAR(1) = '0', --Do not authenticate
	@sendusername VARCHAR(50)	 = NULL,
	@sendpassword VARCHAR(50)	 = NULL
)
AS 

/****************************************** 
This stored procedure takes the parameters and sends an e-mail. All the mail configurations are hard-coded in the stored procedure. Comments are added to the stored procedure where necessary. References to the CDOSYS objects are at the following MSDN Web 
site: http://msdn.microsoft.com/library/default.asp?url=/ library/en-us/cdosys/html/_cdosys_messaging.asp 
*******************************************/ 

Declare @iMsg int


Declare @hr int 
Declare @x int 
Declare @source varchar(255) 
Declare @description varchar(500) 
Declare @output varchar(1000) 

--***** Create the CDO.Message Object ***** 
EXEC @hr = sp_OACreate 'CDO.Message', @iMsg OUT 

--*****Configuring the Message Object ***** 

-- This is to configure a remote SMTP server.
-- http://msdn.microsoft.com/library/default.asp?url=/library/en-us/cdosys/html/_cdosys_schema_configuration_sendusing.asp 
EXEC @hr = sp_OASetProperty @iMsg, 'Configuration.fields ("http://schemas.microsoft.com/cdo/configuration/sendusing").Value','2' 

-- This is to configure the Server Name or IP address. 

-- Replace MailServerName by the name or IP of your SMTP Server.
EXEC @hr = sp_OASetProperty @iMsg, 'Configuration.fields("http://schemas.microsoft.com/cdo/configuration/smtpserver").Value', @SmtpServer 

-- Replace 25 by the PORT SMTP Server.
EXEC @hr = sp_OASetProperty @iMsg, 'Configuration.Fields ("http://schemas.microsoft.com/cdo/configuration/smtpserverport").Value', @SmtpPort


-- Authentication.

EXEC @hr = sp_OASetProperty @iMsg, 'Configuration.Fields ("http://schemas.microsoft.com/cdo/configuration/smtpauthenticate").Value', @smtpauthenticate

-- User / Password
EXEC @hr = sp_OASetProperty @iMsg, 'Configuration.Fields ("http://schemas.microsoft.com/cdo/configuration/sendusername").Value', @sendusername
EXEC @hr = sp_OASetProperty @iMsg, 'Configuration.Fields ("http://schemas.microsoft.com/cdo/configuration/sendpassword").Value', @sendpassword


-- Save the configurations to the message object.
EXEC @hr = sp_OAMethod @iMsg, 'Configuration.Fields.Update', null


-- Set the e-mail parameters.
EXEC @hr = sp_OASetProperty @iMsg, 'To', @To
EXEC @hr = sp_OASetProperty @iMsg, 'From', @From
EXEC @hr = sp_OASetProperty @iMsg, 'Subject', @Subject


IF @AddAttachment IS NOT NULL
BEGIN
	EXEC @hr = sp_OAMethod @iMsg, 'AddAttachment',@x OUT, @AddAttachment
END


-- If you are using HTML e-mail, use 'HTMLBody' instead of 'TextBody'.
EXEC @hr = sp_OASetProperty @iMsg, 'HTMLBody', @Body
EXEC @hr = sp_OAMethod @iMsg, 'Send', NULL


-- Sample error handling. 
	IF @hr <>0 
     BEGIN
       EXEC @hr = sp_OAGetErrorInfo NULL, @source OUT, @description OUT
       IF @hr = 0
         BEGIN
           SELECT @output = '  Source: ' + @source
           PRINT  @output
           SELECT @output = '  Description: ' + @description
           PRINT  @output
         END
       ELSE
         BEGIN
           PRINT '  sp_OAGetErrorInfo failed.'
           RETURN
         END
     END


-- Do some error handling after each step if you have to.
-- Clean up the objects created.
EXEC @hr = sp_OADestroy @iMsg






GO

