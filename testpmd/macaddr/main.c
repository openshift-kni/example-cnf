#include <arpa/inet.h>
#include <getopt.h>
#include <linux/if_ether.h>
#include <linux/if_vlan.h>
#include <linux/virtio_net.h>
#include <linux/virtio_ring.h>
#include <signal.h>
#include <stdint.h>
#include <sys/eventfd.h>
#include <sys/param.h>
#include <unistd.h>

#include <rte_atomic.h>
#include <rte_cycles.h>
#include <rte_ethdev.h>
#include <rte_log.h>
#include <rte_string_fns.h>
#include <rte_malloc.h>
#include <rte_vhost.h>
#include <rte_ip.h>
#include <rte_tcp.h>
#include <rte_pause.h>

#define RTE_LOGTYPE_VHOST_PORT   RTE_LOGTYPE_USER3

#ifndef MAX_QUEUES
#define MAX_QUEUES 128
#endif

/* ethernet addresses of ports */
static struct rte_ether_addr vmdq_ports_eth_addr[RTE_MAX_ETHPORTS];

/* When we receive a INT signal, unregister vhost driver */
static void
sigint_handler(__rte_unused int signum)
{

	exit(0);
}

/*
 * Main function, does initialisation and calls the per-lcore functions.
 */
int
main(int argc, char *argv[])
{
	unsigned nb_ports;
	int ret;
	unsigned idx = 0;
	char mac_string[64];
	char dev_name[64];
	FILE * fp;

	signal(SIGINT, sigint_handler);

	/* init EAL */
	ret = rte_eal_init(argc, argv);
	if (ret < 0)
		rte_exit(EXIT_FAILURE, "Error with EAL initialization\n");
	argc -= ret;
	argv += ret;

	/* Get the number of physical ports. */
	nb_ports = rte_eth_dev_count_avail();
	RTE_LOG(INFO, VHOST_PORT, "nb_borts %d\n", nb_ports);

	fp = fopen("/var/lib/testpmd/macaddr.txt","w");
	for (idx = 0; idx < nb_ports; idx++)
	{
	    rte_eth_macaddr_get(idx, &vmdq_ports_eth_addr[idx]);
	    sprintf(mac_string, "%02"PRIx8":%02"PRIx8":%02"PRIx8":%02"PRIx8":%02"PRIx8":%02"PRIx8,
			vmdq_ports_eth_addr[idx].addr_bytes[0],
			vmdq_ports_eth_addr[idx].addr_bytes[1],
			vmdq_ports_eth_addr[idx].addr_bytes[2],
			vmdq_ports_eth_addr[idx].addr_bytes[3],
			vmdq_ports_eth_addr[idx].addr_bytes[4],
			vmdq_ports_eth_addr[idx].addr_bytes[5]);
	    rte_eth_dev_get_name_by_port(idx, dev_name);
	    RTE_LOG(INFO, VHOST_PORT, "MAC: %s   PCI: %s\n", mac_string, dev_name);
	    fprintf (fp, "%s,%s\n", dev_name, mac_string);
	}
        rte_eal_cleanup();
	fclose (fp);
	return 0;

}
