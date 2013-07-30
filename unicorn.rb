worker_processes 2
working_directory "/sites/zipper.bigfish.co.uk"

preload_app true

timeout 500

listen "/tmp/zipper.sock", :backlog => 64

pid "/tmp/zipper.pid"

stderr_path "/sites/zipper.bigfish.co.uk/err.log"
stdout_path "/sites/zipper.bigfish.co.uk/out.log"
