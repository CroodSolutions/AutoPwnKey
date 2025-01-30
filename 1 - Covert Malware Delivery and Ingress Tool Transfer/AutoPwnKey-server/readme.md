# AutoPwnKey Server Setup

## Prerequisites
- Python 3.11 or higher
- Git

## Installation (Debian)

1. Clone the repository:
```bash
git clone https://github.com/CroodSolutions/AutoPwnKey.git
```

2. Navigate to the server directory:
```bash
cd "AutoPwnKey/1 - Covert Malware Delivery and Ingress Tool Transfer/AutoPwnKey-server"
```

3. Install Python virtual environment package:
```bash
sudo apt install python3.11-venv
```

4. Create and activate virtual environment:
```bash
python3 -m venv venv
source venv/bin/activate
```

5. Install dependencies:
```bash
pip install -r requirements.txt
```

6. Run the server:
```bash
python3 AutoPwnKey-server.py
```

For detailed documentation and usage instructions, please visit our [GitHub repository](https://github.com/CroodSolutions/AutoPwnKey).