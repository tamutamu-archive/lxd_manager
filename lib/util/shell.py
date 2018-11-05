import sys, textwrap
import subprocess as sb

class ShellExec():

    def error_exit_script(self, raw_scripts):
        return textwrap.dedent("""
            set -eu
            {scripts}
        """.format(scripts=raw_scripts)).strip()


    def sh(self, scripts):
        scripts_with_errorh = self.error_exit_script(scripts)

        for line in self.sh_output_generator(scripts_with_errorh):
            sys.stdout.write(line.decode(sys.stdout.encoding))


    def sh_output_generator(self, scripts):
        proc = sb.Popen(scripts, shell=True, stdout=sb.PIPE, stderr=sb.STDOUT)

        while True:
            line = proc.stdout.readline()

            if line:
                yield line

            if not line and proc.poll() is not None:
                break

        if(proc.returncode != 0):
            raise sb.CalledProcessError(proc.returncode, scripts)


    def cmd_out(self, scripts):
        proc = sb.Popen(scripts, shell=True, stdout=sb.PIPE)
        return proc.stdout.read().decode(sys.getdefaultencoding())
