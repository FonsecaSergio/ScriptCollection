CREATE DIAGNOSTICS SESSION ReturnOperationProfile AS N'
<Session>
    <MaxItemCount>10000</MaxItemCount>
    <Filter>
        <Event Name="GeneralInstrumentation:DataReturnProfileEvent" />
    </Filter>
    <Capture>
        <Property Name="DateTimePublished" />
        <Property Name="Session.SessionId" />
        <Property Name="Query.QueryId" />
        <Property Name="CustomContext.TotalRowCount" />
        <Property Name="CustomContext.RowCount" />
        <Property Name="CustomContext.SendRowsFullTime" />
        <Property Name="CustomContext.ResultReadTime" />
        <Property Name="CustomContext.ResultConvertTime" />
        <Property Name="CustomContext.ResultPdwTdsSendRowTime" />
    </Capture>
</Session>';

Select * from sysdiag.ReturnOperationProfile

Drop diagnostics session ReturnOperationProfile;