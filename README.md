# AutoPwnKey
![AutoPwnKey Agent Manager](AgentManager.png)

## --- Introduction ---

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
