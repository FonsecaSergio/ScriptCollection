# ScriptCollection

A personal collection of scripts, queries, troubleshooting snippets, and reference material gathered since 2005 by Sérgio C Fonseca.

The collection focuses on SQL Server, Azure SQL, Azure Synapse Analytics, Microsoft Fabric, and Azure administration, with additional Windows, macOS, Spark, and .NET utilities. It includes both original work and material collected from other authors.

> These are standalone examples and working notes, not a single application or a ready-to-run automation framework. Review and adapt each file before using it. Organization and completeness vary, and older examples may require updates for current services, APIs, or modules.

## Browse the collection

| Folder | Contents |
| --- | --- |
| [SQL](./SQL/) | SQL Server and Azure SQL diagnostics, DMVs, waits and locks, deadlocks, indexes, memory, I/O, tempdb, permissions, Extended Events, storage access, and connection tests. |
| [Synapse](./Synapse/) | Dedicated and serverless SQL examples, query plans, statistics, permissions, pool pause/resume and restore operations, and workspace management through REST APIs. |
| [Fabric](./Fabric/) | Workspace listing, SQL analytics endpoint metadata synchronization/refresh, and SQL request diagnostics. |
| [Data Explorer](./Data%20Explorer/) | REST API scripts to stop running Azure Data Explorer clusters, including an Automation managed identity variant and Synapse-related cluster handling. |
| [Powershell](./Powershell/) | Azure sign-in, service tag IP ranges, SQL RBAC checks, database scaling, resource alerts, and Windows file/system utilities. |
| [LogAnalytics](./LogAnalytics/) | Kusto Query Language (KQL) examples for Azure SQL errors and failed logins in `AzureDiagnostics`. |
| [Spark](./Spark/) | PySpark examples for writing Delta, CSV, and Parquet tables, plus a Spark C# name/IP resolution snippet. |
| [CMD](./CMD/) | Windows command-line notes and examples for remote RunAs, shutdown, and checking elevation. |
| [MAC](./MAC/) | A macOS zsh utility for creating timestamped ZIP backups. |
| [dotNET](./dotNET/) | C# and VB.NET snippets covering proxy accounts, culture, and HTML encoding. |

Bundled external tools are historical copies, not necessarily the latest upstream releases. Read their accompanying documentation and license notices before use.

## Before you run anything

1. **Read the whole file.** Some files contain multiple independent examples, commented alternatives, or incomplete sections rather than one executable workflow.
2. **Replace environment-specific values.** Check subscription and tenant IDs, resource groups, workspaces, servers, database names, storage URLs, local paths, and output destinations. Some examples include masked values such as `******` that must be configured.
3. **Confirm the target and permissions.** Verify the active Azure account/subscription, SQL connection, and resource scope. Use only the privileges required for the task.
4. **Test in a non-production environment first.** Back up relevant data and understand how to reverse changes where possible.
5. **Protect credentials and output.** Do not commit passwords, access tokens, SAS tokens, connection strings containing secrets, or sensitive diagnostic results.

**Potentially disruptive operations are included.** Examples can pause clusters or SQL pools, scale databases, restore pools, kill sessions, clear caches, shrink databases, change permissions, disable constraints, overwrite Spark tables, shut down Windows, or delete files. The duplicate-file utility also has a `-Delete` switch. Do not assume a script is read-only or supports a dry run because of its name or a debug option.

## Prerequisites

Requirements vary by file; there is no collection-wide installation step.

| Script type | What to check |
| --- | --- |
| T-SQL (`.sql`) | A SQL client such as SQL Server Management Studio (SSMS), a compatible SQL Server/Azure SQL/Synapse/Fabric endpoint, and permissions for the statements and diagnostic views used. Syntax and DMV availability differ across engines. |
| PowerShell (`.ps1`) | A compatible PowerShell runtime and the modules imported by that script. Azure examples commonly use `Az.Accounts`, `Az.Sql`, `Az.Synapse`, `Az.Resources`, or `Az.Compute`; some examples use `SqlServer` or `MicrosoftPowerBIMgmt`. |
| Azure Automation / managed identity | An Automation account with the required modules, an enabled managed identity, and appropriate role assignments on the target resources. Older Run As account examples need review before reuse. |
| REST API examples | Authentication for the target API, the required permissions, correct endpoint/resource IDs, and a supported API version. Follow the references in the script and verify current API requirements. |
| SQL connection tests | The client library/provider used by the example. The MSOLEDBSQL variant requires the Microsoft OLE DB Driver for SQL Server. |
| KQL (`.txt`) | A Log Analytics workspace receiving the relevant Azure SQL diagnostic/audit records in `AzureDiagnostics`; adjust time ranges and filters for your data. |
| Spark snippets (`.txt`) | A compatible Spark environment; Delta examples also require Delta Lake support and access to the source data and destination tables. These files are snippets to adapt in a notebook or Spark session. |
| Windows utilities (`.ps1`, `.cmd`, `.txt`) | Windows and any referenced Windows-specific components. Use elevation only when required; Windows Forms, NTFS, and other OS-specific examples are not portable to macOS/Linux. |
| macOS backup (`.command`) | macOS with `/bin/zsh`, readable source files, and a writable destination with sufficient space. Cloud-only files must be downloaded before archiving. |

## Using an example

Clone the repository or download the files you need:

```sh
git clone https://github.com/FonsecaSergio/ScriptCollection.git
cd ScriptCollection
```

Use your own paths. The backup script's built-in defaults are specific to the author's environment; see its header for Finder execution, permissions, and debug behavior.

## Contributions and attribution

Corrections, clearer comments, compatibility updates, and additional examples are welcome. Include the target platform/service, required modules or permissions, configuration steps, and any side effects. Preserve existing author credits and source references, and never include secrets or private environment details.

Some material was collected from the internet over many years. If an attribution is missing or incorrect, please open an issue with the file and original source so the credit can be corrected.

## License

See [LICENSE](./LICENSE) for the repository's MIT license, copyright (c) 2019 Sérgio C Fonseca. 
Third-party scripts and reference material retain their respective license terms and attribution requirements; check accompanying notices