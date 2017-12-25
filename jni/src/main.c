#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <SDL.h>
#include <SDL_opengles2.h>
#include <dlfcn.h>

#include "ecl_boot.h"

int main(int argc, char ** argv)
{
  void * so = NULL;
  char tmp[1024];
  int fd;

  /* Redirecting I/O */
  sprintf(tmp, "%s/output", argv[2]);
  mkfifo(tmp, 0664);
  /* mode is O_RDWR to prevent blocking. Linux-specific. */
  fd = open(tmp, O_RDWR | O_NONBLOCK);
  dup2(fd, 1);
  dup2(fd, 2);
  close(fd);

  sprintf(tmp, "%s/input", argv[2]);
  mkfifo(tmp, 0664);
  fd = open(tmp, O_RDONLY | O_NONBLOCK);
  dup2(fd, 0);
  close(fd);

  ecl_boot(argv[1], argv[3]);

  return 0;
}
