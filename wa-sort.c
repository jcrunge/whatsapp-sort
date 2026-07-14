// wa-sort — Move "WhatsApp *" files out of ~/Downloads into ~/Documents/WhatsApp/_Inbox
//
// A deliberately tiny, single-purpose binary. It takes no arguments, spawns no
// shell, and interprets nothing: it only scans ~/Downloads and moves regular
// files whose name starts with "WhatsApp " into ~/Documents/WhatsApp/_Inbox.
//
// This narrow scope is the whole point: it is meant to be granted macOS Full
// Disk Access on its own, so a background LaunchAgent can tidy Downloads
// without giving broad disk access to /bin/bash (and, transitively, to any
// script an npm postinstall or similar might run).
//
// SPDX-License-Identifier: MIT
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include <dirent.h>
#include <sys/stat.h>
#include <time.h>

static const char *PREFIX = "WhatsApp ";  // files to move must start with this

int main(void) {
    const char *home = getenv("HOME");
    if (!home) return 1;

    char src[1024], docs[1024], dest[1200], log[1300];
    snprintf(src,  sizeof(src),  "%s/Downloads", home);
    snprintf(docs, sizeof(docs), "%s/Documents/WhatsApp", home);
    snprintf(dest, sizeof(dest), "%s/_Inbox", docs);
    snprintf(log,  sizeof(log),  "%s/.wa-sort.log", docs);

    mkdir(docs, 0755);
    mkdir(dest, 0755);

    DIR *d = opendir(src);
    if (!d) return 1;

    size_t plen = strlen(PREFIX);
    FILE *lf = fopen(log, "a");
    struct dirent *e;
    while ((e = readdir(d)) != NULL) {
        if (strncmp(e->d_name, PREFIX, plen) != 0) continue;

        char from[2200], to[2400];
        snprintf(from, sizeof(from), "%s/%s", src, e->d_name);

        // lstat (not stat): only move genuine regular files, never follow a symlink.
        struct stat st;
        if (lstat(from, &st) != 0 || !S_ISREG(st.st_mode)) continue;

        // Move without ever overwriting an existing file: RENAME_EXCL fails with
        // EEXIST if the target exists, so on a name clash we try numbered suffixes.
        snprintf(to, sizeof(to), "%s/%s", dest, e->d_name);
        int moved = (renamex_np(from, to, RENAME_EXCL) == 0);
        for (int n = 1; !moved && errno == EEXIST && n <= 9999; n++) {
            snprintf(to, sizeof(to), "%s/%d_%s", dest, n, e->d_name);
            moved = (renamex_np(from, to, RENAME_EXCL) == 0);
        }

        if (moved && lf) {
            time_t now = time(NULL);
            char ts[32];
            strftime(ts, sizeof(ts), "%Y-%m-%d %H:%M:%S", localtime(&now));
            fprintf(lf, "%s  moved: %s\n", ts, e->d_name);
        }
    }
    if (lf) fclose(lf);
    closedir(d);
    return 0;
}
