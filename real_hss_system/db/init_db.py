import sqlite3
import random
import string
import uuid

def generate_hex(length):
    return ''.join(random.choices(string.hexdigits.upper(), k=length))

def generate_imsi():
    # 450 (South Korea) + 05 (SKT) + 10 digits
    return "45005" + "".join(random.choices(string.digits, k=10))

def generate_msisdn():
    # 82 (Country code) + 10 (Mobile prefix) + 8 digits
    return "8210" + "".join(random.choices(string.digits, k=8))

def setup_database():
    conn = sqlite3.connect('real_hss_system/db/hss_production.db')
    cursor = conn.cursor()

    # Create tables based on realistic HSS schema
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS subscriber_identities (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            imsi VARCHAR(15) UNIQUE NOT NULL,
            msisdn VARCHAR(15) UNIQUE NOT NULL,
            status VARCHAR(10) DEFAULT 'ACTIVE',
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    ''')

    cursor.execute('''
        CREATE TABLE IF NOT EXISTS authentication_vectors (
            imsi VARCHAR(15) PRIMARY KEY,
            ki VARCHAR(32) NOT NULL,
            opc VARCHAR(32) NOT NULL,
            amf VARCHAR(4) DEFAULT '8000',
            sqn VARCHAR(12) DEFAULT '000000000000',
            FOREIGN KEY(imsi) REFERENCES subscriber_identities(imsi)
        )
    ''')
    
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS user_profiles (
            imsi VARCHAR(15) PRIMARY KEY,
            full_name VARCHAR(100),
            resident_id_hash VARCHAR(64),
            address TEXT,
            plan_code VARCHAR(20),
            FOREIGN KEY(imsi) REFERENCES subscriber_identities(imsi)
        )
    ''')

    # Insert 50,000 realistic records
    print("Populating production database with 50,000 records...")
    
    for _ in range(50000):
        imsi = generate_imsi()
        msisdn = generate_msisdn()
        ki = generate_hex(32)
        opc = generate_hex(32)
        
        try:
            cursor.execute("INSERT INTO subscriber_identities (imsi, msisdn) VALUES (?, ?)", (imsi, msisdn))
            cursor.execute("INSERT INTO authentication_vectors (imsi, ki, opc) VALUES (?, ?, ?)", (imsi, ki, opc))
            # Simulating some plaintext personal data which is a common security failure
            cursor.execute("INSERT INTO user_profiles (imsi, full_name, plan_code) VALUES (?, ?, ?)", 
                           (imsi, f"Customer_{generate_hex(6)}", "5G_UNLIMITED"))
        except sqlite3.IntegrityError:
            pass # Skip duplicates if any

    conn.commit()
    conn.close()
    print("Database population complete.")

if __name__ == "__main__":
    setup_database()
