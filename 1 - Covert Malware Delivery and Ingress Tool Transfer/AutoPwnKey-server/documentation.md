# --- Introduction ---

AutoPwnKey is a framework we have created with two purposes in mind. On one hand, we want to raise awareness about the security risk presented by AutoHotKey (and AutoIT). That said, we understand that these problems are unlikely to be resolved anytime soon; at least, if red teams are not using AHK and AutoIT as part of their testing (thus demonstrating the evasiveness). We released BypassIT as a relatively weak framework initially, hoping that proving the evasiveness and capability AutoIT affords attackers would lead to immediate change.  It did not. This time around, we have learned from our mistakes and are trying to release AutoPwnKey in a state where it will be instrumental in helping the Red Teamer(s) succeed in engagements.

Our ultimate goal is to retire this project because AHK based malware and exploits do not work anymore. Until then, we hope AutoPwnKey provides a useful toolset for red teams, setting the foundation for expanded awareness and change in the future.  

## --- Ethical Standards / Code of Conduct ---

This project has been started to help better test products, configurations, detection engineering, and overall security posture against a series of techniques that are being actively used in the wild by adversaries. We can only be successful at properly defending against evasive tactics, if we have the tools and resources to replicate the approaches being used by adversaries in an effective manner. Participation in this project and/or use of these tools implies good intent to use these tools ethically to help better protect/defend, as well as an intent to follow all applicable laws and standards associated with the industry.

## --- Instructions and Overview ---

This framework is structured with hierarchical folders, organized around relevant phases of MITRE ATT&CK. The agent and server provided in initial access, allow for the deployment of most other modules and phases. For red teams operating in the scope of an engagement, you may want to use this as part of a more stealthy approach; such as using AutoPwnKey for initial access to drop some other beacon, then possibly deploy other evasive AHK payloads later managed via AutoPwnKey C2. For blue/purple teams it is far easier - just adapt and run these things and see if your AV/EDR or other tools detect them.  If they do not, open a ticket with your vendors and help raise awareness. If they do catch these tactics right away, also share that and help share successes related to security vendors who are doing a good job of covering these use cases. Sometimes as defenders it seems like the deck is stacked against us. By aligning exploit and evasion research with control refinement and detection engineering, we can both find gaps and also opportunities to better protect and respond.  

## --- How to Contribute ---

We welcome and encourage contributions, participation, and feedback - as long as all participation is legal and ethical in nature. Please develop new scripts, contribute ideas, improve the scripts that we have created. The goal of this project is to come up with a robust testing framework that is available to red/blue/purple teams for assessment purposes, with the hope that one day we can archive this project because improvements to detection logic make this attack vector irrelevant.

1. Fork the project
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## --- Acknowledgments ---

Most of the content here in this form, was the direct creation of [shammahwoods](https://github.com/shammahwoods) as of the time of release, in terms of either creating things outright or porting things over to this new framework. That said, we are building upon the foundation previously built by several other friends/collaborators/researchers including: 
- [Markofka007](https://github.com/Markofka007)
- [AnuraTheAmphibian](https://github.com/AnuraTheAmphibian)
- [christian-taillon](https://github.com/christian-taillon)
- [Duncan4264](https://github.com/Duncan4264)
- [flawdC0de](https://github.com/flawdC0de)
- [Kitsune-Sec](https://github.com/Kitsune-Sec)
- [matt-handy](https://github.com/matt-handy)
- [rayzax](https://github.com/rayzax)

(and many we either forgot to mention or who made key contributions after publication)

# Agents

## Modules

### Basic Commands

#### Command Execution

##### Overview
The Command Execution module enables operators to run system commands on the target system through the AutoPwnKey agent. Commands are executed through the Windows Command Processor and their output is captured and stored in agent-specific log files.

##### Parameters
The module accepts a single parameter:
Command (string): The command to execute on the target system. The command is passed directly to cmd.exe, so standard command prompt syntax applies.

##### Usage
1. Select the target agent from the agents table (top left)
2. Select "Command Execution" from the modules panel (top right)
3. Enter the desired command in the parameter input field
4. Click "Queue Command" to send the command
5. Monitor the server log panel (bottom left) for execution status
6. View command output in the output panel (bottom right)

##### Security Considerations
Commands execute with the same privileges as the AutoPwnKey agent process. Interactive commands requiring user input will cause the agent to block since the implementation only supports initial command execution and output capture. The agent will remain unresponsive until the blocking command completes or times out.

##### Technical Details
Command Execution Flow:
- Commands are queued server-side and stored with the target agent ID
- During agent check-in, the command is retrieved via the "execute_command" action
- The agent executes the command using WScript.Shell through cmd.exe
- Standard output (StdOut) is captured and returned via "command_output" message
- Output is stored in logs/output_{agent_id}.txt and displayed in the command output panel

Output Format:
- Successful execution returns the complete StdOut buffer
- Empty StdOut returns "(Empty)"
- Failed execution returns "Execution Failed: {error message}"
- All output is logged with timestamps and agent identifiers

##### Example Impact
When executing the command `systeminfo`:
- Server log shows command queued for agent
- Agent retrieves command during next check-in
- Command executes through cmd.exe
- StdOut containing system information is captured
- Output is stored in logs/output_{agent_id}.txt
- System details appear in command output panel
- Server log confirms successful execution

##### Troubleshooting
Common issues:
- No output displayed: Verify command generates StdOut (not StdErr)
- Agent unresponsive: Check for interactive commands blocking execution
- Command fails: Verify syntax and required privileges
- Output truncated: Be aware of buffer limitations in cmd.exe

#### WinGet PS Execution

##### Overview
This module leverages Windows Package Manager (WinGet) as a LOLBIN to execute PowerShell scripts through its configuration functionality. By using a legitimate Windows binary, this technique often bypasses standard detection methods, making it valuable for security control testing.

##### Parameters
PowerShell Script (text): The PowerShell commands to execute on the target system. Multiple commands can be separated by newlines with semicolon terminiators

##### Usage
1. Select the target agent from the agents table
2. Select "WinGet PowerShell Execution" from the modules panel
3. Enter your PowerShell script in the editor
4. Use the toolbar to load/save scripts for reuse
5. Click "Run Script" to queue execution
6. Monitor the server log panel for execution status
7. View any output in the command output panel

##### Security Considerations
The module executes PowerShell commands through WinGet's configuration system, running with the same privileges as the agent process. This technique leverages WinGet as a Living Off the Land Binary, utilizing legitimate Windows functionality in a way that may bypass traditional security controls.

##### Technical Details
**Execution Flow:**
- The server converts the PowerShell script into a WinGet configuration YAML file
- The YAML file is transferred to the agent system
- WinGet executes the configuration with agreements pre-accepted and interactivity disabled
- If the script writes to C:\Temp\log.txt, contents are captured and returned
- The configuration uses PSDscResources/Script resource for execution

**Implementation Notes:**
- Output capture requires scripts to write to C:\Temp\log.txt
- The module uses WinGet's configuration version 0.2.0
- Script execution is non-interactive by design
- Configuration files are uniquely named per agent

##### Example Impact
When executing the default script:
- Creates/overwrites C:\Temp\log.txt
- Logs PowerShell host information
- Captures current execution policy
- Returns contents through command output channel

##### Troubleshooting
- No output received: Verify script writes to C:\Temp\log.txt
- Execution fails: Check WinGet installation on target
- Permission errors: Verify agent has access to Temp directory
- Configuration errors: Ensure WinGet version compatibility

### Discovery

#### Basic Recon

##### Overview
The Basic Reconnaissance module executes a series of built-in Windows commands to gather system and network information from the target environment. This module provides rapid situational awareness by collecting system specifications and active network connections.

##### Parameters
This module requires no parameters or configuration. It executes a predefined set of reconnaissance commands automatically.

##### Usage
1. Select the target agent from the agents table
2. Select "Basic Reconnaissance" from the modules panel
3. Click "Queue Module" to initiate the reconnaissance
4. View collected information in the output panel

##### Security Considerations
The commands executed by this module generate Windows Event Log entries that security tools may monitor. Specifically:
- SystemInfo execution creates Event ID 4688 (Process Creation) logs
- Network enumeration commands may trigger alerts in security monitoring tools
- Command execution patterns may be detected by behavioral analytics

##### Technical Details
The module sequentially executes these commands:
- systeminfo: Collects detailed system configuration data including OS version, hardware specifications, and patch levels
- arp -a: Displays the current ARP cache, showing IP-to-MAC address mappings for network interfaces

The execution occurs through the Windows Command Processor, with output captured and returned through the standard command output channel.

##### Example Impact
The module returns comprehensive system data including:
- Operating system version and architecture
- Installed security updates and hotfixes
- Hardware specifications and memory configuration
- Network interface configurations
- Current ARP table entries and network mappings

##### Troubleshooting
- Delayed response: System information collection may take time on complex systems
- Incomplete data: Verify agent has sufficient permissions to execute system queries
- Network data unavailable: Check network interface status and permissions

#### Discover PII

##### Overview
The PII Discovery module performs targeted scanning of text files within a specified directory to identify potential personally identifiable information (PII). This module is designed for security testing scenarios to evaluate how sensitive information might be exposed in text files across a system, and if EDR products will detect exfiltration.

##### Parameters
Directory Path (string): Target directory to scan recursively. If not specified, defaults to the user's Documents folder.
- Example: C:\Users\Administrator\Documents

Context Length (integer): Number of characters to capture before and after each match (1-1000, default: 30).
- Smaller values (10-20) provide focused context for quick pattern verification
- Larger values (50-100) help understand how the PII is used in broader context
- Default value of 30 balances context with output readability

##### Usage
1. Select the target agent from the agents table
2. Select "PII Discovery" from the modules panel
3. Enter the directory path to scan (optional)
4. Adjust the context length if desired
5. Click "Queue Module" to initiate the scan
6. Review discovered patterns in the output panel

##### Technical Details
The module searches for these specific patterns:
- Phone Numbers: (###) ###-####, ###-###-####, and similar formats
- Social Security Numbers: ###-##-####
- Dates: MM/DD/YYYY, YYYY/MM/DD, and similar formats

Implementation Notes:
- Scans only .txt files recursively in the specified directory
- Each match includes the specified amount of context before and after
- Results are grouped by file for easy analysis
- Only successfully read files are included in results
- Empty directories or those without .txt files return appropriate notifications

##### Troubleshooting
- No results: Verify directory contains .txt files with matching content
- Access denied: Check agent permissions on target directory

#### Enumerate DCs

##### Overview
This module identifies and lists all Domain Controllers (DCs) in the current Active Directory domain using the Windows `nltest` utility. It provides essential information about the domain's authentication infrastructure.

##### Parameters
This module requires no parameters. It automatically queries the current domain based on the system's domain membership.

##### Usage
1. Select the target agent from the agents table
2. Select `DC Enumeration` from the modules panel
3. Click `Queue Module` to initiate the enumeration
4. View results in the output panel

##### Security Considerations
Domain Controller enumeration activities may be logged in the following locations:
- Windows Event Logs on Domain Controllers
- Network security monitoring systems
- Active Directory audit logs

The module uses standard Windows utilities, though repeated queries may trigger security alerts.

##### Technical Details
**Requirements:**
- Agent must be running on a domain-joined system
- Network connectivity to Domain Controllers
- Standard domain user privileges or higher
- Functioning DNS resolution to the domain

The module executes `nltest /dclist` against the current domain, captured from the system's environment variables. Results include the Domain Controller hostnames, IP addresses, and site information where available.

##### Example Impact
Successful execution provides a detailed listing of Domain Controllers, enabling understanding of the domain's authentication infrastructure and potential targets for further investigation.

#### Domain Trusts

##### Overview
This module enumerates trust relationships between the current domain and other Active Directory domains or forests using the Windows `nltest` utility. It reveals the broader Active Directory federation landscape.

##### Parameters
This module requires no parameters. It automatically analyzes trust relationships for the current domain.

##### Usage
1. Select the target agent from the agents table
2. Select `Domain Trusts` from the modules panel
3. Click `Queue Module` to initiate trust enumeration
4. View trust relationships in the output panel

##### Security Considerations
Trust enumeration activities may generate:
- Security event logs on Domain Controllers
- Alerts in Active Directory monitoring systems
- Network detection of domain trust queries

While using standard Windows tools, this reconnaissance activity may indicate potential lateral movement preparation.

##### Technical Details
**Requirements:**
- Domain-joined system
- Network access to Domain Controllers
- Standard domain user privileges
- Proper DNS configuration for domain resolution

The module leverages `nltest /trusted_domains` to identify bidirectional, incoming, and outgoing trust relationships between domains.

##### Example Impact
Successful execution maps the trust relationships between domains, revealing potential paths for lateral movement and privilege escalation across domain boundaries.

#### Port Scanner

##### Overview
The Port Scanner module performs TCP connection attempts to detect open ports and services on target systems. While primarily designed for testing EDR detection capabilities of port scanning activity, it can also provide basic network service enumeration.

##### Parameters
Target IPs (string): IP address or range to scan.
- Single IP: `192.168.1.1`
- CIDR notation: `192.168.1.0/24`

Ports (string): Ports or port ranges to scan.
- Single port: `80`
- Port range: `20-25`
- Multiple ports/ranges: `20-25,53,80,443`

If no ports are specified, the module defaults to scanning commonly targeted ports: 20-25 (FTP/SMTP), 53 (DNS), 80 (HTTP), 110 (POP3), 111 (RPC), 135 (MSRPC), 139 (NetBIOS), 143 (IMAP), 443 (HTTPS), 445 (SMB), 993 (IMAPS), 995 (POP3S), 1723 (PPTP), 3306 (MySQL), 3389 (RDP), 5900 (VNC), 8080 (HTTP Proxy), 9929 (Nping), and 31337.

##### Usage
1. Select the target agent from the agents table
2. Select "Port Scanner" from the modules panel
3. Enter target IP address or range
4. Specify ports to scan (optional)
5. Click "Queue Module" to initiate the scan
6. Monitor progress in the output panel

##### Technical Details
The scanner operates by attempting TCP connections to each specified port, with results classified into three states:

Open: Successfully established TCP connection, indicating an active service
Closed: Target actively refused the connection attempt
Filtered: No response received within timeout period, suggesting potential firewall filtering

Implementation Characteristics:
- Uses synchronous TCP connections with 3-second timeout
- Performs sequential rather than parallel scanning
- Reports real-time progress as percentage complete
- Provides service name identification for common ports

Performance Considerations:
The module's scanning speed is constrained by its sequential operation and fixed 3-second timeout period. This results in predictable but relatively slow scanning times:

Single IP scan (20 ports): ~1 minute
/24 network (256 IPs, 20 ports): ~4-5 hours

Due to these performance characteristics, this module is best suited for:
- Testing EDR detection of port scanning activity
- Small-scale service enumeration
- Security control validation

##### Example Output
The module provides detailed scan results in this format:
```
Starting scan of 192.168.1.1 at 2025-02-11 14:30
Not shown: 18 closed tcp ports
PORT      STATE    SERVICE
80/tcp    open     http
443/tcp   filtered https
Scan completed in 61.23 seconds
```

##### Troubleshooting
- Slow scan completion: Expected due to sequential scanning and timeout values
- Missing results: Check network connectivity and firewall rules
- Filtered results: May indicate network security controls or implementation limits

### Evasion

#### Deny Outbound Firewall

##### Overview
This module creates Windows Firewall rules to block outbound network connections for specified security product executables found in the Program Files directory. By preventing these products from communicating externally, the module can be used to test security control resilience and outbound blocking detection capabilities.

##### Parameters
Target File Names (text): Comma-separated list of executable base names to search for and block. Names are not case sensitive.

Example targets: `csfalconservice`, `sentinelone`, `cylancesvc`, `SEDservice`

##### Usage
1. Select the target agent from the agents table
2. Select "Deny Outbound Firewall" from the modules panel
3. Enter target executable names in the parameter field
4. Click "Queue Module" to initiate the firewall rule creation
5. Review the output panel for identified executables and rule creation status

##### Security Considerations
This module requires administrative privileges to create firewall rules. When executed, it will prevent the targeted security products from communicating with their management servers, which may:
- Trigger offline alerts or notifications
- Cause products to enter a failsafe or enforcement mode
- Generate suspicious activity alerts for firewall manipulation
- Create Windows Event Log entries for firewall rule modifications

##### Technical Details
The module operates in several stages:
1. Verifies administrative privileges
2. Recursively searches Program Files for matching executable names
3. Creates outbound block rules using Windows Advanced Firewall
4. Returns status for each rule creation attempt

The search process will temporarily block agent communication until completion. Rules are created using the netsh command with specific targeting by executable path.

##### Example Impact
When targeting an endpoint protection executable:
- Outbound communications to management servers are blocked
- Policy updates and threat intelligence feeds are interrupted
- Command and control from security operations is prevented
- Product may enter an offline operational mode

##### Troubleshooting
- Access Denied: Verify agent is running with administrative privileges
- No Files Found: Confirm correct executable names and search paths
- Delayed Response: Large Program Files directories may increase search time

#### Deny Outbound Firewall

##### Overview
This module creates Windows Firewall rules to block outbound network connections for specified security product executables found in the Program Files directory. By preventing these products from communicating externally, the module can be used to test security control resilience and outbound blocking detection capabilities.

##### Parameters
Target File Names (text): Comma-separated list of executable base names to search for and block. Names are not case sensitive.

Example targets: `csfalconservice`, `sentinelone`, `cylancesvc`, `SEDservice`

##### Usage
1. Select the target agent from the agents table
2. Select "Deny Outbound Firewall" from the modules panel
3. Enter target executable names in the parameter field
4. Click "Queue Module" to initiate the firewall rule creation
5. Review the output panel for identified executables and rule creation status

##### Security Considerations
This module requires administrative privileges to create firewall rules. When executed, it will prevent the targeted security products from communicating with their management servers, which may:
- Trigger offline alerts or notifications
- Cause products to enter a failsafe or enforcement mode
- Generate suspicious activity alerts for firewall manipulation
- Create Windows Event Log entries for firewall rule modifications

##### Technical Details
The module operates in several stages:
1. Verifies administrative privileges
2. Recursively searches Program Files for matching executable names
3. Creates outbound block rules using Windows Advanced Firewall
4. Returns status for each rule creation attempt

The search process will temporarily block agent communication until completion. Rules are created using the netsh command with specific targeting by executable path.

##### Example Impact
When targeting an endpoint protection executable:
- Outbound communications to management servers are blocked
- Policy updates and threat intelligence feeds are interrupted
- Command and control from security operations is prevented
- Product may enter an offline operational mode

##### Troubleshooting
Common issues:
- Access Denied: Verify agent is running with administrative privileges
- No Files Found: Confirm correct executable names and search paths
- Rule Creation Failure: Check Windows Firewall service status
- Delayed Response: Large Program Files directories may increase search time

#### Host File URL Block

##### Overview
This module modifies the Windows hosts file to redirect specified domains to a target IP address, effectively blocking or redirecting outbound traffic to those domains. This technique can be used to test network security controls and DNS-based detection mechanisms.

##### Parameters
Target URLs (text): Comma-separated list of domain names to block or redirect. Each domain entered will generate two entries in the hosts file - one for the base domain and one with "www." prepended.

Example input: `securityvendor.com, updates.vendor.com`

##### Usage
1. Select the target agent from the agents table
2. Select "Host File URL Block" from the modules panel
3. Enter target domains in the parameter field
4. Click "Queue Module" to initiate the hosts file modification
5. Review the output panel for successful entry creation status

##### Security Considerations
This module requires administrative privileges to modify the hosts file located at `C:\Windows\System32\drivers\etc\hosts`. When executed, it will:
- Create permanent DNS resolution entries until manually removed
- Affect all applications and services that rely on DNS resolution
- Generate system events related to hosts file modifications
- Potentially trigger security alerts for system file modifications

The module can be used for DNS poisoning attacks by redirecting traffic to specified IP addresses. You should carefully consider the implications of redirecting specific domains and ensure all modifications align with testing scope.

##### Technical Details
The module performs the following operations:
1. Verifies administrative privileges
2. Opens the hosts file in append mode
3. For each specified domain, creates two entries:
   - `127.0.0.1 domain.com`
   - `127.0.0.1 www.domain.com`
4. Returns status for each entry creation

Multiple executions will create duplicate entries, as the module appends without checking for existing entries.

##### Example Impact
When targeting a domain:
- All local DNS resolution attempts for the domain are redirected
- Applications cannot reach the original domain IP
- Web browsers and services will fail to connect
- Services may experience timeouts or connection errors

##### Troubleshooting
- Access Denied: Verify agent has administrative privileges
- File Locked: Check for applications holding a lock on the hosts file
- DNS Resolution: Some applications may cache DNS results
- Duplicate Entries: Multiple executions create additional entries

#### Unhook NTDLL

##### Overview
This module implements an NTDLL unhooking technique by restoring clean copies of hooked functions from disk. It specifically targets EDR hooks commonly placed in NTDLL.dll for security monitoring, providing a method to restore the original, unmodified system functionality.

##### Usage
1. Select the target agent from the agents table
2. Select `Unhook NTDLL` from the modules panel
3. Click `Queue Module` to initiate the unhooking process
4. Monitor the command output panel for operation status

##### Security Considerations
EDR products commonly implement function hooks within NTDLL.dll to monitor system operations. These hooks intercept calls to critical functions such as `NtCreateFile`, `NtOpenProcess`, and other Native API functions. By removing these hooks, this module may:

- Bypass EDR monitoring capabilities
- Disable security event reporting for NTDLL operations
- Trigger alerts in sophisticated security monitoring systems that detect hook removal

##### Technical Implementation
The unhooking process follows a sophisticated multi-step approach:

1. Initial Setup
   - Validates current NTDLL state and cleans up any existing modifications
   - Retrieves current process memory information
   - Locates NTDLL base address in memory

2. Clean File Access
   The module implements a two-stage mapping process for secure file access:
   
   First Stage:
   - Creates a file handle to with GENERIC_READ and FILE_SHARE_READ|WRITE access
   - Establishes a read-only file mapping for `%WinDir%\System32` using PAGE_READONLY protection
   - Maps the file with FILE_MAP_READ permissions into process memory
   
   Second Stage:
   - Validates file mapping integrity before proceeding
   - Maintains separate handles for file and mapping objects
   - Implements proper handle cleanup sequence to prevent resource leaks

3. PE Header Processing
   - Parses the DOS header to locate PE information
   - Identifies section headers and their characteristics
   - Specifically targets the `.text` section containing executable code

4. Memory Manipulation
   - Changes memory protection to allow modifications
   - Performs chunked memory copies (4KB blocks) for stability
   - Implements memory barriers to ensure cache coherency
   - Restores original memory protection settings

Memory Management:
- Uses `VirtualProtect` with `PAGE_EXECUTE_READWRITE` temporarily
- Implements proper cleanup of file handles and mapped views
- Maintains process working set size monitoring
- Employs instruction cache flushing for consistency

Memory Operations:
- Implements chunked copying to prevent large memory operations
- Uses 4KB aligned blocks to match system page size
- Performs sequential validation of copied memory regions
- Maintains working set size monitoring during operations

Section Processing:
- Validates both virtual and raw data information
- Handles section alignment requirements
- Processes PE sections iteratively with error handling
- Maintains section characteristics during restoration

The copy process specifically:
1. Calculates optimal chunk size based on section characteristics
2. Validates source and destination addresses for each chunk
3. Performs RtlCopyMemory operations with integrity checks
4. Handles remainder bytes separately to maintain alignment
5. Verifies copy completion with memory comparison

##### Error Handling

1. Retry Logic:
   - Initial operation attempts timeout after 5 seconds
   - Memory protection changes retry up to 3 times
   - Section processing includes error recovery

2. Error Codes:
    - Error 5 (Access Denied): Insufficient privileges or locked memory pages
    - Error 87 (Invalid Parameter): Misaligned memory addresses or invalid sizes
    - Error 998 (Invalid Access): Memory region already mapped or protected
    - Error 1450 (Insufficient System Resources): Memory pressure or handle limits


##### Diagnostic Information
Detailed logging is implemented throughout the process:

1. Debug Log Location: `ntdll_debug.log`
2. Log Contents:
   - PE header processing details
   - Memory operation results
   - Protection change tracking
   - Error conditions and recovery attempts

This log file can be retrieved using the file transfer functionality for detailed troubleshooting.

##### Example Impact
When successfully executed, the module:
- Restores original NTDLL functionality
- Removes EDR monitoring hooks
- Enables direct system calls without security product interception
- May affect EDR visibility of subsequent operations

##### Troubleshooting
- Access Denied: Check agent privileges. Admin is not required
- Timeout Failures: Check system resource availability
- Section Processing Errors: Review debug logs for specific failure points
- Memory Protection Failures: Verify no conflicting security products

### Privilege Escalation

#### Run As User

##### Overview
This module creates a new instance of the AutoPwnKey agent running under specified user credentials. It accomplishes this by copying the necessary files to a public directory and launching them with alternate user credentials, resulting in a separate agent connection with different permissions and context.

##### Parameters
Username (text): The Windows username to run the new agent instance as
Example: `Administrator`

Password (text): The corresponding password for the specified user account
Example: `Password123`

##### Usage
1. Select the target agent from the agents table
2. Select "Run As User" from the modules panel
3. Enter the target username and password
4. Click "Queue Module" to initiate the new agent instance
5. Monitor the agents table for the new connection

##### Security Considerations
This module handles sensitive credentials and creates persistent files on the target system. Key security implications include:
- Plain text credentials are transmitted to the agent
- Required files are copied to `C:\Users\Public\Temp`
- The new agent process operates with full user context
- Windows security logs will show process creation and user authentication events

##### Technical Details
The module executes the following sequence:
1. Creates `C:\Users\Public\Temp` if it doesn't exist
2. Copies the AutoHotkey executable and agent script to this location
3. Launches a new process using the specified credentials
4. Creates a new agent connection with a unique Agent ID

The new agent operates independently of the original, resulting in two active connections identifiable by different Agent IDs in the management interface. The Agent ID is derived from system information and the script path, ensuring each instance has a unique identifier.

##### Example Impact
When successfully executed:
- New agent process appears in Windows task manager
- Additional agent connection appears in the management interface
- Files persist in the Public\Temp directory
- New agent operates with specified user's permissions and context

##### Troubleshooting
- Access Denied: Verify credentials are valid and active
- Missing Agent: Verify the new Agent ID appears in the management interface

### Persistence

#### Add Admin User

##### Overview
This module creates a new local user account and adds it to the local Administrators group, establishing a persistent administrative presence on the target system. The module leverages the Windows API through NetUserAdd and NetLocalGroupAddMembers functions.

##### Parameters
- Username: The desired username for the new account (Default: `TestUser`)
- Password: Account password that meets system requirements (Default: `P@ssw0rd123!`)
- Full Name: Display name for the account (Default: `Test User`)

##### Usage
1. Select the target agent from the agents table
2. Select `Add Administrative User` from the modules panel
3. Enter desired username, password, and full name (or use defaults)
4. Click `Queue Module` to initiate user creation
5. Monitor the command output panel for success confirmation

##### Security Considerations
This module requires administrative privileges on the target system and generates multiple high-visibility events in the Windows Event Log, including:
- Event ID 4720: A user account was created
- Event ID 4728: A member was added to a security-enabled global group
- Event ID 4732: A member was added to a security-enabled local group

Administrative user creation is often monitored by security tools and may trigger immediate alerts.

##### Technical Details
The module performs two primary operations:
1. Creates a local user account through the NetUserAdd API
2. Adds the new user to the Administrators group via NetLocalGroupAddMembers

Password requirements are enforced by the local system's password policy, which typically includes:
- Minimum length requirements
- Complexity requirements (uppercase, lowercase, numbers, special characters)
- History requirements (cannot reuse recent passwords)

Detailed execution logs are stored on the agent side and can be retrieved using the file transfer functionality in the GUI.

##### Example Impact
Successful execution results in:
- New local user account with specified credentials
- Administrative privileges granted to the new account
- Ability to authenticate with the created account locally and over supported remote protocols

##### Troubleshooting
- Access Denied: Verify agent is running with administrative privileges
- Account Creation Failure: Check password meets local policy requirements
- Group Addition Failure: Ensure Administrators group exists and is accessible
- Detailed logs can be retrieved from the agent for additional error information

#### Add Startup to Registry

##### Overview
This module establishes persistence by creating an auto-start registry entry in the current user's Run key. When the user logs in, the registry key executes the AutoHotkey agent using the installed AutoHotkey interpreter.

##### Parameters
- Key Name: The name of the registry value to create (Default: `StartUp`)

##### Usage
1. Select the target agent from the agents table
2. Select `Registry Run Key` from the modules panel
3. Enter desired registry value name or use default
4. Click `Queue Module` to create the registry entry

##### Security Considerations
This persistence method operates in user context and does not require administrative privileges. The registry modification creates a new value in `HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run`, which is a commonly monitored location for persistence mechanisms.

The modification generates Windows Registry events that security tools may monitor:
- Event ID 4657: A registry value was modified
- Event ID 4663: An attempt was made to access an object
- Process creation events when the entry executes at login

##### Technical Details
The module creates a registry value containing two components:
1. The path to the installed AutoHotkey interpreter
2. The full path to the agent script file

When the user logs in, Windows automatically executes all entries in the Run key with the user's security context. This ensures the agent maintains the same permissions and access level as the user who installed it.

##### Example Impact
Successful execution results in:
- New registry value in the user's Run key
- Automatic agent execution upon user login
- Persistence maintained with user-level privileges

##### Troubleshooting
- Registry access denied: Verify user has permission to modify Run key

#### Add Scheduled Task

##### Overview
This module establishes persistence by creating a recurring scheduled task on the target system. By default, it creates a task that re-launches the agent executable every 24 hours, though it can be configured to execute any specified program or command.

##### Parameters
- Task Name: Identifier for the scheduled task (Default: `ScheduledTask`)
- Action: Program or command to execute (Default: Agent's own executable)
- Delay Hours: Initial delay before first execution (Default: `24`)

##### Usage
1. Select the target agent from the agents table
2. Select `Create Scheduled Task` from the modules panel
3. Customize the task name if desired
4. Specify an alternate program/command or leave blank for agent persistence
5. Set the desired initial delay in hours
6. Click `Queue Module` to create the task

##### Security Considerations
The module automatically selects the highest available privilege level for task execution. When running with administrative privileges, the task executes as the SYSTEM account. Without administrative access, it runs in the current user's context.

Task creation generates Windows Event Log entries, specifically:
- Event ID 4698: A scheduled task was created
- Event ID 4699: A scheduled task was deleted (if replacing existing task)
- Event ID 4702: A scheduled task was updated

The task is configured to run hidden from the Windows Task Scheduler interface to reduce visibility.

##### Technical Details
Task Configuration:
- Executes daily after the specified initial delay
- Hidden from Task Scheduler interface
- Allows manual start (AllowDemandStart enabled)
- Will run at next opportunity if scheduled time is missed (StartWhenAvailable enabled)
- Runs with highest available privileges (SYSTEM if admin, user context if not)

Command Handling:
- Empty action parameter defaults to agent persistence
- Quoted commands preserve spaces in paths and parameters
- Arguments are properly separated from the executable path

##### Example Impact
Default Configuration Results:
- Hidden scheduled task created
- Task configured to launch agent every 24 hours
- Task runs as SYSTEM if available
- Persistence survives system reboots
- Task begins execution after specified delay

##### Troubleshooting
- Access Denied: Check privilege level for desired execution context
- Command Parsing Error: Ensure proper quoting for paths with spaces
- Execution Failure: Verify specified program path and permissions

### Lateral Movement

#### Install MSI

##### Overview
This module facilitates lateral movement by downloading and silently installing MSI packages on the target system. It defaults to installing PuTTY, a legitimate remote access tool, but can be configured to install any accessible MSI package. The module attempts user-level installation for evasion while maintaining administrative privileges for broad compatibility.

##### Parameters
- Download URL: Source location for the MSI package (Default: `https://the.earth.li/~sgtatham/putty/latest/w64/putty-64bit-0.82-installer.msi`)
- Download Path: Temporary location for the installer (Default: `%TEMP%\putty-installer.msi`)
- Install Directory: Target installation directory (Default: `%APPDATA%\PuTTY`)

##### Usage
1. Select the target agent from the agents table
2. Select `Install MSI Package` from the modules panel
3. Optionally modify the download URL, path, or installation directory
4. Click `Queue Module` to initiate the installation
5. Monitor the command output panel for the installation result code

##### Security Considerations
The module employs several techniques to balance functionality with evasion:
- Requires administrative privileges for broad compatibility
- Attempts user-level installation when supported (`MSIINSTALLPERUSER=1`)
- Uses legitimate software installation mechanisms
- Leverages known remote access tools that may already be allowlisted
- Performs silent installation to minimize user awareness

##### Technical Details
Installation Process:
1. Creates installation directory if needed
2. Downloads MSI package to temporary location (`%TEMP%`)
3. Executes msiexec with silent installation parameters
4. Attempts user-level installation
5. Removes downloaded installer package
6. Returns installation result code

Common Result Codes:
- `0`: Successful installation
- `1602`: User cancelled installation
- `1603`: Fatal error during installation
- `1619`: Installation source not accessible
- `3010`: Success but requires restart

System Paths:
- `A_Temp` resolves to `C:\Users\{username}\AppData\Local\Temp`
- `A_AppData` resolves to `C:\Users\{username}\AppData\Roaming`

##### Example Impact
Successful execution results in:
- Silent installation of specified MSI package
- Installation contained to user context if supported
- Legitimate software available for remote access
- No user interaction or prompts displayed

##### Troubleshooting
- Access Denied: Verify agent has administrative privileges
- Download Failure: Confirm URL accessibility and network connectivity
- Installation Failure: Check MSI package compatibility with silent installation
- Path Issues: Ensure specified directories are accessible to the agent

#### RDP Connection

##### Overview
This module establishes an RDP connection to a target system and automates the deployment of an AutoPwnKey agent. It handles the complete process from connection establishment through agent installation, providing automated lateral movement capabilities.

##### Parameters
- Hostname/IP: Target system address (Default: `192.168.124.125`)
- Username: Account for RDP authentication (Default: `Administrator`)
- Password: Account password (Default: `hunter2`)
- Domain: Optional domain for authentication (Default: `lab.local`)
- C2 Server IP: IP address for the new agent to connect to (Default: `192.168.124.22`)

##### Usage
1. Select the target agent from the agents table
2. Select `RDP Connection` from the modules panel
3. Enter the target system credentials and C2 server information
4. Click `Queue Module` to initiate the connection sequence
5. Monitor the command output panel for completion confirmation

##### Security Considerations
This module generates significant activity that security tools may detect:
- RDP connection events in Windows Event Log
- Credential storage using Windows Credential Manager
- Network connections to `GitHub.com` for agent installation
- Command prompt execution and file downloads using curl
- AutoHotkey installation and script execution

Network requirements include access to:
- Target system over RDP (`TCP 3389`)
- `GitHub.com` for AutoHotkey installer download
- Raw GitHub content for agent script retrieval
- Specified C2 server IP for new agent connection

##### Technical Details
The module executes the following sequence:
1. Creates a temporary RDP configuration file with specified parameters
2. Stores credentials in Windows Credential Manager
3. Initiates RDP connection and handles security prompts
4. Opens command prompt on target system
5. Downloads and installs AutoHotkey (approximately 3 second wait)
6. Downloads agent script (approximately 3 second wait)
7. Launches agent with provided C2 server IP
8. Minimizes and then closes the command prompt window
9. Cleans up temporary RDP configuration file

The entire process includes several timed delays totaling approximately 15 seconds to ensure reliable execution across different system configurations.

##### Example Impact
Successful execution results in:
- Established RDP connection to target system
- AutoHotkey installation in user profile directory
- New AutoPwnKey agent connecting to specified C2 server
- Temporary files removed from source system

##### Troubleshooting
- RDP Connection Failure: Verify network connectivity and credentials
- Download Failures: Confirm access to GitHub domains
- Timing Issues: System performance may require adjusted delays
- Agent Connection Failure: Verify network path to C2 server

### Impact

#### Encrypt Files

##### Overview
This module implements a file encryption system using the Windows CryptoAPI to recursively encrypt all files within a specified directory. It provides a mechanism to protect or restrict access to data by encrypting files with AES encryption, making them inaccessible without the correct password.

##### Parameters
- Directory: Full path to the target directory (Default: `C:\Users\Administrator\Documents`)
- Password: Encryption key for securing the files (Default: `P@ssw0rd123!`)

##### Usage
1. Select the target agent from the agents table
2. Select `Encrypt Files` from the modules panel
3. Enter the target directory path and desired encryption password
4. Click `Queue Module` to initiate the encryption process
5. Monitor the command output panel for completion status

##### Security Considerations
This module implements serious changes to the target system that require careful consideration:

The encryption process is irreversible without the correct password. Encrypting system directories or user profiles can permanently impact system functionality and potentially render the system inoperable. Exercise extreme caution when selecting target directories.

The encryption implementation uses the Windows CryptoAPI with the following specifications:
- Algorithm: `AES (Advanced Encryption Standard)`
- Provider Type: `PROV_RSA_AES (1)`
- Algorithm Identifier: `CALG_AES_256 (0x6801)`
- Key Derivation: `Password-based through CryptDeriveKey`

##### Technical Details
The encryption process follows these steps:
1. Recursively identifies all files in the target directory and subdirectories
2. Processes each file individually:
  - Reads the file content as binary data
  - Creates a cryptographic context using Windows CryptoAPI
  - Derives an encryption key from the provided password
  - Encrypts the file content using AES encryption
  - Writes the encrypted data to a new file with `.encrypted` extension
  - Removes the original file

The module implements safeguards against repeated encryption by skipping any files that already have the `.encrypted` extension.

Detailed execution logs are stored on the agent side and can be retrieved using the file transfer functionality in the GUI.

##### Example Impact
When targeting a user's Documents folder:
- All files within the directory and subdirectories are encrypted
- Original files are replaced with encrypted versions
- Each encrypted file has `.encrypted` appended to its name
- Files become inaccessible without the encryption password

##### Troubleshooting
- Access Denied: Verify file permissions in target directory
- Partial Encryption: Check logs for specific file failures
- Memory Constraints: Large files may require additional system resources
- System Files: Some files may be locked by the operating system

#### Decrypt Files

##### Overview
This module reverses the encryption performed by the `Encrypt Files` module, restoring files to their original state using the Windows CryptoAPI. It specifically targets files with the `.encrypted` extension that were processed by its companion encryption module.

##### Parameters
- Directory: Full path to the directory containing encrypted files (Default: `C:\Users\Administrator\Documents`)
- Password: The original encryption password used to secure the files (Default: `P@ssw0rd123!`)

##### Usage
1. Select the target agent from the agents table
2. Select `Decrypt Files` from the modules panel
3. Enter the directory path containing encrypted files
4. Provide the original encryption password
5. Click `Queue Module` to begin the decryption process
6. Monitor the command output panel for completion status

##### Security Considerations
The success of this module depends entirely on using the correct password from the original encryption operation. Incorrect passwords will result in corrupted file data that may not be recoverable. The module specifically requires that files were encrypted using the Directory Encryption module, as it relies on the same cryptographic implementation:
- Algorithm: `AES (Advanced Encryption Standard)`
- Provider Type: `PROV_RSA_AES (1)`
- Algorithm Identifier: `CALG_AES_256 (0x6801)`
- Key Derivation: `Password-based through CryptDeriveKey`

##### Technical Details
The decryption process operates exclusively on files with the `.encrypted` extension, following these steps:
1. Recursively identifies all files ending in `.encrypted` within the target directory
2. For each encrypted file:
  - Reads the encrypted content as binary data
  - Establishes a cryptographic context using Windows CryptoAPI
  - Derives the decryption key using the provided password
  - Attempts to decrypt the file content
  - Removes the `.encrypted` extension and restores the original file
  - Deletes the encrypted version upon successful decryption

Files without the `.encrypted` extension are ignored, as they were not processed by the encryption module. Detailed execution logs are stored on the agent side and can be retrieved using the file transfer functionality in the GUI.

##### Example Impact
When targeting a directory containing encrypted files:
- `document.pdf.encrypted` becomes `document.pdf`
- Files decrypt to their original format and content
- Successfully decrypted files have their `.encrypted` versions removed
- Files without the `.encrypted` extension remain unchanged

##### Troubleshooting
- Incorrect Password: Results in corrupted output files
- Missing Files: Verify files have `.encrypted` extension
- Access Denied: Check file permissions in target directory
- Partial Recovery: Review agent logs for specific file failures

