#include <unistd.h>
#include <stdio.h>
#include <time.h>
#include <libgen.h> /* basename */
#include <stdlib.h> /* exit */

char *arg0;

void usage(void) {
	printf("Usage: %s {-b | -m | -r}\n", arg0);
	exit(2);
}

int main(int argc, char *argv[]) {
	int r, opt, nsec = 0;
	clockid_t c = CLOCK_REALTIME;
	struct timespec t;

	arg0 = basename(argv[0]);

	while ((opt = getopt(argc, argv, "bmr")) != -1) {
		switch (opt) {
		case 'b':
			c = CLOCK_BOOTTIME; break;
		case 'm':
			c = CLOCK_MONOTONIC; break;
		case 'r':
			c = CLOCK_REALTIME; break;
		default:
			usage();
		}
	}

	r = clock_gettime(c, &t);
	if (r < 0) {
		perror("clock_gettime");
		return 1;
	}

	if (nsec)
		printf("%ld.%9lu\n", t.tv_sec, t.tv_nsec);
	else
		printf("%ld\n", t.tv_sec);

	return 0;
}
