/* $Id$ */

/*
 * Copyright (c) 2004 Nicholas Marriott <nicholas.marriott@gmail.com>
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF MIND, USE, DATA OR PROFITS, WHETHER
 * IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING
 * OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 */

#include <sys/types.h>
#include <sys/param.h>

#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#include "logfmon.h"

int
save_cache(void)
{
	struct file	*file;
	FILE		*fd;
	char		 path[MAXPATHLEN];
	int		 res;

	if (conf.cache_file == NULL || *conf.cache_file == '\0')
		return (0);

	log_debug("saving cache");

	res = xsnprintf(path, sizeof path, "%s.new", conf.cache_file);
	if (res < 0) {
		log_warnx("bad cache file");
		return (1);
	}

	fd = fopen(path, "w+");
	if (fd == NULL) {
		log_warn("%s", path);
		return (1);
	}

	TAILQ_FOREACH(file, &conf.files, entry) {
		if (fprintf(fd, "%lu %s 0 %lld\n",
		    (unsigned long) strlen(file->path), file->path,
		    (long long) file->offset) == -1) {
			fclose(fd);
			log_warnx("error writing cache");
			unlink(path);
			return (1);
		}
	}

	fclose(fd);

	if (rename(path, conf.cache_file) != 0) {
		log_warn("rename");
		unlink(path);
		return (1);
	}

	return (0);
}

int
load_cache(void)
{
	struct file	*file;
	FILE		*fd;
	char		 path[MAXPATHLEN], fmt[32];
	off_t		 off;
	int		 res;
	unsigned int	 len;

	if (conf.cache_file == NULL || *conf.cache_file == '\0')
		return (0);

	log_debug("loading cache");

	fd = fopen(conf.cache_file, "r");
	if (fd == NULL) {
		log_warn("cache not loaded. %s", conf.cache_file);
		return (1);
	}

	while (!feof(fd)) {
		if (fscanf(fd, "%u ", &len) != 1)
			break;
		if (len >= sizeof path)
			goto error;

		res = xsnprintf(fmt, sizeof fmt, "%%%uc %%*lld %%lld", len);
		if (res < 0)
			goto error;

		memset(path, 0, sizeof path);
		if (fscanf(fd, fmt, path, &off) != 2)
			goto error;
		path[len] = '\0';

		file = find_file_by_path(path);
		if (file != NULL) {
			file->offset = off;
			log_debug("file %s, was %lld now %lld",
			    path, off, file->offset);
		}
	}

	fclose(fd);
	return (0);

error:
	log_warnx("cannot load cache; possibly corrupted");

	fclose(fd);
	return (1);
}
