#Requires AutoHotkey v2.0

; This script attempts to covertly check the domain for unconstrained delegation opportunities.

CheckUnconstrainedDelegation() {
    outputFile := "Output.txt"
    resultText := ""
    
    try {
        ; First check if we can access AD using a different method
        domainInfo := ComObject("ADSystemInfo")
        domainDNS := domainInfo.DomainDNSName
        
        ; Now connect using LDAP with the domain DNS name
        conn := ComObject("ADODB.Connection")
        conn.Provider := "ADsDSOObject"
        conn.Open("Active Directory Provider")
        
        ; Create command object
        cmd := ComObject("ADODB.Command")
        cmd.ActiveConnection := conn
        
        ; Build LDAP query using domain DNS name
        baseDN := JoinDNComponents(domainDNS)
        query := "<LDAP://" baseDN ">;(&(objectCategory=computer)(userAccountControl:1.2.840.113556.1.4.803:=524288));cn,distinguishedName,dNSHostName;subtree"
        cmd.CommandText := query
        
        ; Set command properties
        cmd.Properties["Page Size"] := 1000
        cmd.Properties["Timeout"] := 30
        cmd.Properties["Cache Results"] := false
        
        ; Execute query
        rs := cmd.Execute()
        
        ; Process results
        while !rs.EOF {
            computerName := rs.Fields["cn"].Value
            dnsName := rs.Fields["dNSHostName"].Value
            dn := rs.Fields["distinguishedName"].Value
            
            resultText .= Format("Computer: {}`nDNS Name: {}`nDN: {}`n`n", computerName, dnsName, dn)
            rs.MoveNext()
        }
    } catch as err {
        FileAppend "Error: " err.Message "`nPlease verify machine is domain-joined and you have appropriate permissions.`n", outputFile
        return
    }
    
    ; Cleanup
    if IsSet(rs)
        rs.Close()
    if IsSet(conn)
        conn.Close()
    
    ; Write output
    try {
        if FileExist(outputFile)
            FileDelete(outputFile)
        
        if (resultText = "") {
            FileAppend "No computers with unconstrained delegation were found.`n", outputFile
        } else {
            FileAppend resultText, outputFile
        }
    } catch as err {
        FileAppend "Error writing results: " err.Message "`n", outputFile
    }
}

JoinDNComponents(domainName) {
    components := StrSplit(domainName, ".")
    result := ""
    for component in components {
        if (result != "")
            result .= ","
        result .= "DC=" component
    }
    return result
}

; Run the check
CheckUnconstrainedDelegation()
