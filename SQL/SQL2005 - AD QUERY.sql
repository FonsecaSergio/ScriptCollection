/************************************************
Author: Sergio Fonseca
Twitter @FonsecaSergio
Email: sergio.fonseca@microsoft.com
Last Update Date: ?
************************************************/

http://fsuid.fsu.edu/admin/lib/WinADLDAPAttributes.html

SELECT [displayName] AS [Nome_Completo]
FROM OPENQUERY(ADSIXPTO, 
'SELECT displayName FROM ''LDAP://test.com/DC=XPTO,DC=XPTO2,DC=com'' where objectClass = ''User''')


SELECT     displayName AS [Nome_Completo], givenName AS [Primeiro_Nome], sn AS [Sobre_Nome], Title AS [Cargo], 
                      Company AS [Empresa], sAMAccountName AS [Usuario_Rede], mail AS [email], telephoneNumber AS [Telefone], 
                      department AS [Departamento], l AS [Cidade], wWWHomePage AS [Usuario_BPCS], CASE cast(pwdLastSet AS bigint) 
                      WHEN 0 THEN 0 ELSE dateadd(day, (cast(pwdLastSet AS float) / 10000000 / 3600 / 24) - 147558 + 90, '2005-01-01') END AS [Senha_Expira], 
                      physicalDeliveryOfficeName AS [Escritorio], st AS [Exibe_Foto], UserAccountControl AS [Numero_Objeto], pager AS [Ramal], 
                      userAccountControl AS [CONTROLE]
FROM         OPENQUERY(ADSIXPTO, 
                      'SELECT pager, useraccountcontrol, st, physicalDeliveryOfficeName, pwdLastSet, wWWHomePage, l, department, telephoneNumber, mail,
sAMAccountName, Company, Title, sn, givenName, displayName
FROM ''LDAP://cpssads01.XPTO.XPTO2.com/DC=XPTO,DC=XPTO2,DC=com'' where objectClass = ''User'' and 
objectClass=''user'' and userAccountControl<1000')


/****** Object:  LinkedServer [ADSIXPTO]    Script Date: 09/08/2010 11:23:13 ******/
EXEC master.dbo.sp_addlinkedserver @server = N'ADSIXPTO', @srvproduct=N'Active Directory Service Interfaces', @provider=N'ADSDSOObject', @datasrc=N'adsdatasource'
/* For security reasons the linked server remote logins password is changed with ######## */
EXEC master.dbo.sp_addlinkedsrvlogin @rmtsrvname=N'ADSIXPTO',@useself=N'False',@locallogin=NULL,@rmtuser=N'XPTO\acataneoadm',@rmtpassword='########'

GO
EXEC master.dbo.sp_serveroption @server=N'ADSIXPTO', @optname=N'collation compatible', @optvalue=N'false'
GO
EXEC master.dbo.sp_serveroption @server=N'ADSIXPTO', @optname=N'data access', @optvalue=N'true'
GO
EXEC master.dbo.sp_serveroption @server=N'ADSIXPTO', @optname=N'dist', @optvalue=N'false'
GO
EXEC master.dbo.sp_serveroption @server=N'ADSIXPTO', @optname=N'pub', @optvalue=N'false'
GO
EXEC master.dbo.sp_serveroption @server=N'ADSIXPTO', @optname=N'rpc', @optvalue=N'false'
GO
EXEC master.dbo.sp_serveroption @server=N'ADSIXPTO', @optname=N'rpc out', @optvalue=N'false'
GO
EXEC master.dbo.sp_serveroption @server=N'ADSIXPTO', @optname=N'sub', @optvalue=N'false'
GO
EXEC master.dbo.sp_serveroption @server=N'ADSIXPTO', @optname=N'connect timeout', @optvalue=N'0'
GO
EXEC master.dbo.sp_serveroption @server=N'ADSIXPTO', @optname=N'collation name', @optvalue=null
GO
EXEC master.dbo.sp_serveroption @server=N'ADSIXPTO', @optname=N'lazy schema validation', @optvalue=N'false'
GO
EXEC master.dbo.sp_serveroption @server=N'ADSIXPTO', @optname=N'query timeout', @optvalue=N'0'
GO
EXEC master.dbo.sp_serveroption @server=N'ADSIXPTO', @optname=N'use remote collation', @optvalue=N'true'
