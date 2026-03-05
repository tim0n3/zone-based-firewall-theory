MikroTik Zone-Based Firewall (ZBF) InfographicThis document visualises the architecture and packet flow of your new ZBF setup. It is broken down into three distinct views: High-Level Architecture, Full RouterOS Packet Flow, and ZBF Matrix Logic.1. High-Level Zone ArchitectureThis diagram illustrates the permitted traffic flows between your defined interface lists (Zones) and the router itself.graph TD
    %% Define Styles
    classDef router fill:#2c3e50,stroke:#ecf0f1,stroke-width:2px,color:#fff;
    classDef wan fill:#c0392b,stroke:#ecf0f1,color:#fff;
    classDef lan fill:#27ae60,stroke:#ecf0f1,color:#fff;
    classDef vpn fill:#2980b9,stroke:#ecf0f1,color:#fff;
    classDef drop fill:#7f8c8d,stroke:#fff,stroke-dasharray: 5 5,color:#fff;

    %% Nodes
    RTR{MikroTik Router<br/>[INPUT / OUTPUT]}:::router
    WAN([WAN Zone<br/>Internet]):::wan
    LAN([LAN Zone<br/>Local Net]):::lan
    VPN([VPN Zone<br/>WireGuard/Tunnels]):::vpn

    %% Forward Flows (Through Router)
    LAN ==>|LAN-WAN Chain<br/>Allow All Egress| WAN
    LAN <==>|LAN-VPN / VPN-LAN Chains<br/>Allow All Bidirectional| VPN
    WAN -.->|WAN-LAN Chain<br/>Strictly DST-NAT Only| LAN

    %% Input Flows (To Router)
    LAN -->|LAN-ROUTER Chain<br/>DNS, DHCP, Mgmt| RTR
    VPN -->|VPN-ROUTER Chain<br/>Mgmt, ICMP| RTR
    WAN -.->|WAN-ROUTER Chain<br/>WG Handshakes, ICMP| RTR

    %% Default Drops
    WAN -.-x|Default Drop| RTR
    WAN -.-x|Default Drop| VPN
2. Full RouterOS Packet Flow ContextYour firewall doesn't just use the filter table; it heavily relies on raw, mangle, and nat. This diagram maps a packet entering your router from the WAN, showing exactly where your existing rules and the new ZBF rules intersect.flowchart TD
    classDef raw fill:#8e44ad,color:#fff,stroke:#fff;
    classDef mangle fill:#d35400,color:#fff,stroke:#fff;
    classDef nat fill:#f39c12,color:#fff,stroke:#fff;
    classDef filter fill:#2980b9,color:#fff,stroke:#fff;
    classDef routing fill:#34495e,color:#fff,stroke:#fff;
    classDef endnode fill:#27ae60,color:#fff,stroke:#fff;
    classDef dropnode fill:#c0392b,color:#fff,stroke:#fff;

    Start([Packet Ingress (e.g., WAN)]) --> RAW
    
    subgraph PREROUTING [Prerouting Phase]
        RAW[RAW Table<br/>Drops TCP 0, Bogons, Bad Flags]:::raw --> MANGLE_PRE[MANGLE Table<br/>Marks QoS Packets/Conns]:::mangle
        MANGLE_PRE --> DSTNAT[NAT Table<br/>Evaluates Port Forwards/dstnat]:::nat
    end

    DSTNAT --> ROUTING{Routing Decision<br/>Is destination the Router itself?}:::routing

    ROUTING -- YES --> INPUT_CHAIN
    ROUTING -- NO --> FORWARD_CHAIN

    subgraph INPUT [Filter: INPUT Chain]
        INPUT_CHAIN[GLOBAL INPUT<br/>Accept Est/Rel, Drop Invalid]:::filter --> IN_JUMP{Match Interface List}:::filter
        IN_JUMP -- WAN --> IN_WAN[WAN-ROUTER Chain]:::filter
        IN_WAN --> IN_EVAL{Matches Rule?}
        IN_EVAL -- Yes --> ACCEPT_IN([Accept to Local Process]):::endnode
        IN_EVAL -- No --> IN_RETURN[Return to Global]:::filter
        IN_RETURN --> IN_DROP([Drop by Default]):::dropnode
    end

    subgraph FORWARD [Filter: FORWARD Chain]
        FORWARD_CHAIN[GLOBAL FORWARD<br/>Accept Est/Rel, Drop Invalid]:::filter --> FW_JUMP{Match In/Out Interface Lists}:::filter
        FW_JUMP -- In:WAN Out:LAN --> FW_WANLAN[WAN-LAN Chain]:::filter
        FW_WANLAN --> FW_EVAL{Matches Rule?<br/>e.g., connection-nat-state=dstnat}
        FW_EVAL -- Yes --> ACCEPT_FW([Accept & Route to LAN]):::endnode
        FW_EVAL -- No --> FW_RETURN[Return to Global]:::filter
        FW_RETURN --> FW_DROP([Drop by Default]):::dropnode
    end

    ACCEPT_FW --> MANGLE_POST[MANGLE Postrouting]:::mangle
    MANGLE_POST --> SRCNAT[NAT Table<br/>Source NAT / Masquerade]:::nat
    SRCNAT --> Egress([Packet Egress])
3. ZBF Matrix Logic (The Forward Chain)This zoom-in shows the exact logical sequence your router executes when a packet attempts to traverse between interfaces. This is the core of the "Jump" matrix.flowchart TD
    classDef pass fill:#2ecc71,color:#fff,stroke:#fff;
    classDef drop fill:#e74c3c,color:#fff,stroke:#fff;
    classDef jump fill:#3498db,color:#fff,stroke:#fff;
    classDef eval fill:#f1c40f,color:#333,stroke:#333;

    Start([Packet enters Filter FORWARD]) --> GlobalAccept{Is state Established,<br/>Related, or Untracked?}:::eval
    
    GlobalAccept -- YES --> ACCEPT([ACCEPT & PASS]):::pass
    GlobalAccept -- NO --> GlobalDrop1{Is state Invalid?}:::eval
    
    GlobalDrop1 -- YES --> DROP1([DROP: Invalid]):::drop
    GlobalDrop1 -- NO --> GlobalDrop2{Is it DNS Hijack<br/>or Huawei Block?}:::eval
    
    GlobalDrop2 -- YES --> DROP2([REJECT: Global Block]):::drop
    GlobalDrop2 -- NO --> JumpMatrix[Evaluate Jump Matrix]:::jump
    
    JumpMatrix --> Match1{In: LAN<br/>Out: WAN?}:::eval
    Match1 -- YES --> Chain1[LAN-WAN Chain]:::jump
    Match1 -- NO --> Match2{In: LAN<br/>Out: VPN?}:::eval
    
    Match2 -- YES --> Chain2[LAN-VPN Chain]:::jump
    Match2 -- NO --> Match3{In: VPN<br/>Out: LAN?}:::eval
    
    Match3 -- YES --> Chain3[VPN-LAN Chain]:::jump
    Match3 -- NO --> Match4{In: WAN<br/>Out: LAN?}:::eval
    
    Match4 -- YES --> Chain4[WAN-LAN Chain]:::jump
    Match4 -- NO --> DefaultDrop([DROP: Global Default Drop<br/>Log: FW-DROP-ALL]):::drop
    
    Chain1 --> Rules1[Process LAN-WAN Rules]
    Rules1 --> EndRules1{Matched an Accept?}
    EndRules1 -- YES --> ACCEPT
    EndRules1 -- NO --> Return1[Return to Global] --> DefaultDrop
    
    Chain4 --> Rules4[Process WAN-LAN Rules]
    Rules4 --> EndRules4{Is it a Port Forward<br/>or Safezone?}
    EndRules4 -- YES --> ACCEPT
    EndRules4 -- NO --> Return4[Return to Global] --> DefaultDrop
