# ghost-coder.ps1 - "คอมมีชีวิต"
# รอจนไม่มีการขยับเมาส์/พิมคีย์บอร์ดครบตามเวลา แล้วเปิด VS Code พิมโค้ดเอง
# ขยับเมาส์เอง เปิด terminal รันคำสั่งเอง — พอมีคนแตะเครื่องจริง จะหยุดทันที
# หยุดโปรแกรม: ปิดหน้าต่างคอนโซลนี้ หรือกด Ctrl+C
param([switch]$TestNow, [switch]$SelfTest)

# ---- ปรับได้ตรงนี้ ----
$IdleMinutes = 3      # นาทีที่เครื่องต้องว่างก่อนผีเริ่มทำงาน
$KeyDelayMin = 35     # ms ต่อตัวอักษร (เร็วสุด)
$KeyDelayMax = 160    # ms ต่อตัวอักษร (ช้าสุด)
$ThinkChance = 3      # % โอกาสหยุดคิดกลางคัน
$TypoChance  = 2      # % โอกาสพิมผิดแล้วลบแก้
# -----------------------

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class Ghost {
    [StructLayout(LayoutKind.Sequential)]
    public struct LASTINPUTINFO { public uint cbSize; public uint dwTime; }
    [DllImport("user32.dll")] public static extern bool GetLastInputInfo(ref LASTINPUTINFO plii);
    [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
    [DllImport("user32.dll")] public static extern int GetWindowText(IntPtr hWnd, System.Text.StringBuilder text, int count);
    public static uint LastInputTick() {
        LASTINPUTINFO l = new LASTINPUTINFO();
        l.cbSize = (uint)Marshal.SizeOf(l);
        GetLastInputInfo(ref l);
        return l.dwTime;
    }
}
"@

# ponytail: TickCount วนซ้ำทุก ~25 วัน — เครื่องเปิดยาวขนาดนั้นค่อยรีสตาร์ทโปรแกรม
function Get-IdleMs { [Environment]::TickCount - [Ghost]::LastInputTick() }

$script:lastSend = [Ghost]::LastInputTick()

function Send-Chunk([string]$keys) {
    [System.Windows.Forms.SendKeys]::SendWait($keys)
    $script:lastSend = [Ghost]::LastInputTick()
}

# ถ้า last input ใหม่กว่าคีย์ล่าสุดที่เราส่งเอง = คนจริงแตะเครื่อง
function Test-UserBack { ([Ghost]::LastInputTick() - $script:lastSend) -gt 150 }

function Escape-Key([string]$c) {
    if ('+^%~(){}[]'.Contains($c)) { "{$c}" } else { $c }
}

function Get-ForegroundTitle {
    $sb = New-Object System.Text.StringBuilder 512
    [void][Ghost]::GetWindowText([Ghost]::GetForegroundWindow(), $sb, 512)
    $sb.ToString()
}

function Focus-VSCode {
    if ((Get-ForegroundTitle) -like '*Visual Studio Code*') { return $true }
    $shell = New-Object -ComObject WScript.Shell
    [void]$shell.AppActivate('Visual Studio Code')
    Start-Sleep -Milliseconds 800
    return ((Get-ForegroundTitle) -like '*Visual Studio Code*')
}

# ขยับเมาส์แบบนุ่มๆ (SetCursorPos ไม่นับเป็น input เลยไม่หลอก idle detector ของตัวเอง)
function Move-MouseDrift {
    $b = [System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea
    $tx = Get-Random -Minimum ([int]($b.Width * 0.2)) -Maximum ([int]($b.Width * 0.8))
    $ty = Get-Random -Minimum ([int]($b.Height * 0.2)) -Maximum ([int]($b.Height * 0.8))
    $p = [System.Windows.Forms.Cursor]::Position
    $steps = Get-Random -Minimum 20 -Maximum 45
    for ($i = 1; $i -le $steps; $i++) {
        $t = $i / $steps
        $e = $t * $t * (3.0 - 2.0 * $t)
        $x = [int]($p.X + ($tx - $p.X) * $e)
        $y = [int]($p.Y + ($ty - $p.Y) * $e)
        [System.Windows.Forms.Cursor]::Position = New-Object System.Drawing.Point -ArgumentList $x, $y
        Start-Sleep -Milliseconds (Get-Random -Minimum 6 -Maximum 18)
    }
}

# พิมข้อความทีละตัวอักษรแบบคน: จังหวะสุ่ม หยุดคิด พิมผิดแล้วลบ
# คืนค่า $false ถ้าคนจริงกลับมา หรือ VS Code หลุดโฟกัส (จะได้ไม่พิมใส่หน้าต่างอื่น)
function Type-Human([string]$text) {
    foreach ($line in ($text -split "`r?`n")) {
        if (Test-UserBack) { return $false }
        if (-not ((Get-ForegroundTitle) -like '*Visual Studio Code*')) { return $false }
        foreach ($ch in $line.ToCharArray()) {
            if (Test-UserBack) { return $false }
            if (($ch -match '[a-zA-Z]') -and ((Get-Random -Maximum 100) -lt $TypoChance)) {
                Send-Chunk ([string][char](Get-Random -Minimum 97 -Maximum 123))
                Start-Sleep -Milliseconds (Get-Random -Minimum 250 -Maximum 600)
                Send-Chunk '{BACKSPACE}'
                Start-Sleep -Milliseconds (Get-Random -Minimum 100 -Maximum 300)
            }
            Send-Chunk (Escape-Key ([string]$ch))
            Start-Sleep -Milliseconds (Get-Random -Minimum $KeyDelayMin -Maximum $KeyDelayMax)
            if ((Get-Random -Maximum 100) -lt $ThinkChance) {
                Start-Sleep -Milliseconds (Get-Random -Minimum 900 -Maximum 3500)
            }
        }
        # ESC กัน suggestion popup, Shift+Home+Del ลบ auto-indent ที่ VS Code แถมมา
        Send-Chunk '{ESC}{ENTER}+{HOME}{DEL}'
        Start-Sleep -Milliseconds (Get-Random -Minimum 150 -Maximum 700)
        if ((Get-Random -Maximum 100) -lt 20) { Move-MouseDrift }
    }
    return $true
}

$Snippets = @(
@'
# quicksort.py
def quicksort(items):
    if len(items) <= 1:
        return items
    pivot = items[0]
    less = [x for x in items[1:] if x < pivot]
    more = [x for x in items[1:] if x >= pivot]
    return quicksort(less) + [pivot] + quicksort(more)

data = [7, 2, 9, 4, 1, 8]
print(quicksort(data))
'@,
@'
# todo_app.py
import json

class TodoList:
    def __init__(self, path):
        self.path = path
        self.items = []

    def add(self, text):
        self.items.append({"text": text, "done": False})

    def save(self):
        with open(self.path, "w") as f:
            json.dump(self.items, f, indent=2)

todos = TodoList("todo.json")
todos.add("feed the cat")
todos.add("take over the world")
todos.save()
print("saved", len(todos.items), "tasks")
'@,
@'
// stars.js - tiny star field
const stars = [];
for (let i = 0; i < 64; i++) {
    stars.push({
        x: Math.random() * 800,
        y: Math.random() * 600,
        speed: 0.5 + Math.random() * 2,
    });
}

function tick() {
    for (const s of stars) {
        s.x -= s.speed;
        if (s.x < 0) s.x = 800;
    }
}
setInterval(tick, 16);
console.log("universe running...");
'@
)

# คำสั่งใน terminal — เอาแบบไม่มีพิษภัยเท่านั้น
$Commands = @('echo hello... anyone here?', 'python --version', 'dir', 'git status')

function Run-TerminalCommand {
    if (-not (Focus-VSCode)) { return $false }
    Send-Chunk '^`'
    Start-Sleep -Milliseconds 1500
    $cmd = $Commands | Get-Random
    foreach ($ch in $cmd.ToCharArray()) {
        if (Test-UserBack) { return $false }
        Send-Chunk (Escape-Key ([string]$ch))
        Start-Sleep -Milliseconds (Get-Random -Minimum $KeyDelayMin -Maximum $KeyDelayMax)
    }
    Send-Chunk '{ENTER}'
    Start-Sleep -Milliseconds (Get-Random -Minimum 2500 -Maximum 5000)
    Send-Chunk '^`'   # ซ่อน terminal กลับ
    Start-Sleep -Milliseconds 600
    return $true
}

function Start-Session {
    Write-Host ('{0:HH:mm:ss} เครื่องว่างครบ {1} นาที — ผีเริ่มเขียนโค้ด' -f (Get-Date), $IdleMinutes)
    Start-Process -FilePath 'cmd.exe' -ArgumentList '/c', 'code', '-n' -WindowStyle Hidden
    $ok = $false
    for ($i = 0; $i -lt 20; $i++) {
        Start-Sleep -Seconds 1
        if (Focus-VSCode) { $ok = $true; break }
    }
    if (-not $ok) {
        Write-Host 'เปิด/โฟกัส VS Code ไม่ได้ — พัก 60 วิแล้วลองใหม่'
        Start-Sleep -Seconds 60
        return
    }
    $script:lastSend = [Ghost]::LastInputTick()
    Start-Sleep -Seconds 2
    while ($true) {
        Send-Chunk '^n'
        Start-Sleep -Milliseconds 900
        if (-not (Type-Human ($Snippets | Get-Random))) { break }
        Move-MouseDrift
        Start-Sleep -Milliseconds (Get-Random -Minimum 1500 -Maximum 4000)
        if (-not (Run-TerminalCommand)) { break }
        # นั่งมองงานตัวเองแป๊บนึง แล้วเริ่มไฟล์ใหม่
        Start-Sleep -Milliseconds (Get-Random -Minimum 3000 -Maximum 9000)
    }
    Write-Host ('{0:HH:mm:ss} มีคนแตะเครื่อง — ผีหยุด กลับไปรอรอบใหม่' -f (Get-Date))
}

if ($SelfTest) {
    Write-Host ('OK: idle ตอนนี้ = {0} วินาที' -f [int]((Get-IdleMs) / 1000))
    if (Get-Command code -ErrorAction SilentlyContinue) { Write-Host 'OK: เจอ VS Code CLI' }
    else { Write-Host "WARN: ไม่เจอคำสั่ง 'code' ใน PATH" }
    Write-Host ('OK: escape test = ' + (Escape-Key '{') + (Escape-Key 'a') + (Escape-Key '+'))
    exit 0
}

Write-Host ('ghost-coder ทำงานแล้ว — จะเริ่มพิมเองเมื่อไม่มีใครแตะเครื่อง {0} นาที (ปิดหน้าต่างนี้เพื่อหยุด)' -f $IdleMinutes)
while ($true) {
    if (-not $TestNow) {
        while ((Get-IdleMs) -lt ($IdleMinutes * 60000)) { Start-Sleep -Seconds 5 }
    }
    $TestNow = $false
    Start-Session
    Start-Sleep -Seconds 5
}
