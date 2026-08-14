# 📦 Mini-Jail

A lightweight, pure-Bash container runtime demonstrating how Docker and Kubernetes enforce resource limits under the hood using **Linux Control Groups (cgroups v2)**.

## 🚀 Usage

```bash
chmod +x jail.sh
sudo ./jail.sh <Memory_MB> <CPU_%> <Command>


🧪 Fun Examples to Try
1. The Safe Command
Run a simple ls command with a 50MB RAM limit and 100% CPU allowance.

Bash
sudo ./jail.sh 50 100 ls -la

2. The CPU Hog (Watch it get throttled)
Run an infinite Python loop and restrict it to 20% of a single CPU core.

Bash
sudo ./jail.sh 50 20 python3 -c "while True: pass"
(Open another terminal and type top to watch python3 flatline at exactly 20.0% CPU usage!)

3. The Memory Hog (Watch it die)
Run a Python script that slowly attempts to eat 100MB of RAM. The jail is set to 50MB.

Bash
sudo ./jail.sh 50 100 python3 -c "import time; a=''; 
for i in range(10): 
    a += ' ' * (10*1024*1024); 
    print(f'Ate {(i+1)*10}MB...'); 
    time.sleep(1)"
(Watch the kernel instantly snipe the process the millisecond it hits 51MB).

🧠 How it Works (Under the Hood)
In Linux, "Everything is a file." This script interacts directly with the pseudo-filesystem located at /sys/fs/cgroup/.

Creating the Cgroup: The script runs mkdir /sys/fs/cgroup/my_jail. The kernel intercepts this and populates the folder with control files.

Setting the Limits:

It writes bytes into memory.max to enforce RAM ceilings.

It writes a timeframe quota into cpu.max to enforce CPU throttling.

Trapping the Process: It writes its own Process ID ($$) into cgroup.procs. This locks the shell session (and any commands it runs) inside the limits.

Telemetry: When the command finishes, the script reads memory.events to check if the kernel had to step in and kill the process.

⚙️ Requirements
A Linux distribution utilizing cgroups v2 (Ubuntu 20.04+, Debian 11+, Fedora, etc.)

Root privileges (sudo)


### 3. Push to GitHub
1. Initialize your folder: `git init`
2. Add the files: `git add jail.sh README.md`
3. Commit them: `git commit -m "Initial commit: Added jail.sh and documentation"`
4. Push to your new GitHub repository!