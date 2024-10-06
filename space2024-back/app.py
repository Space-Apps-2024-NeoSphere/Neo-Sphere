from flask import Flask, request, g, session, redirect, url_for
from markupsafe import escape
import os
import mysql.connector
import hashlib, datetime, random, base64, json, email
import validators

app = Flask(__name__)
app.secret_key = os.getenv("SECRET_KEY", 'dev')

DBNAME = os.getenv("DB_NAME", 'test')
TABLE = os.getenv("DB_TABLE", 'tabl')
FROM_MAIL_ID = os.getenv("SUPPORT_MAIL_ID")
FROM_MAIL_PSWD = os.getenv("SUPPORT_MAIL_PSWD")
DB_HOST = os.getenv("DB_HOST", 'localhost')
DB_USER = os.getenv("DB_USER", "admin")
DB_PASSWORD = os.getenv("DB_PASSWORD", 'Sudo L0g1n')

AKEYS_GLOBAL = {}
RESET_DAT = {}

# TODO: Get the next item url
def get_next_item(username):
    pass

# TODO: get the user's progress
def get_user_progress(username):
    pass

def gen_access_key(username):
    d = datetime.datetime.today()
    rand = random.randint(1024, 1048576)
    akey = str(username) + '-' + str(d.timestamp()) + '-' + str(rand)
    if username in AKEYS_GLOBAL.keys():
        AKEYS_GLOBAL[str(username)].append(rand)
    else:
        AKEYS_GLOBAL[str(username)] = [rand,]

    return base64.b64encode(bytes(akey.encode()))

def validate_akey(akey, username):
    ak = akey
    akey_dec = str(base64.b64decode(ak)).split('-')
    uname = akey_dec[0]
    timestamp = akey_dec[1]
    rand = akey_dec[2]

    if rand not in AKEYS_GLOBAL[username]:
        return False, {}
    
    if uname != username:
        return False, {}
    
    tst = datetime.datetime.fromtimestamp(float(timestamp))
    if datetime.datetime.today().date() > (tst + datetime.timedelta(days=30)):
        return False, {}

    if datetime.datetime.today().date() > (tst + datetime.timedelta(days=7)):
        ak = refresh_token(ak)
    
    return True, {"ACCESS-TOKEN": ak}

def refresh_token(akey):
    akey_dec = str(base64.b64decode(akey).decode()).split('-')
    uname = akey_dec[0]
    timestamp = akey_dec[1]
    rand = akey_dec[2]

    d = datetime.datetime.today()
    timestamp = d.timestamp()
    AKEYS_GLOBAL[uname].remove(rand)
    rand = random.randint(1024, 1048576)
    AKEYS_GLOBAL[uname].append(rand)

    akey_ref = uname + str(timestamp) + str(rand)
    return base64.b64encode(akey_ref.encode())

def get_db():
    if 'db' not in g:
        g.db = mysql.connector.connect(host=DB_HOST, user=DB_USER, password=DB_PASSWORD, database=DBNAME)
    return g.db

def close_db():
    db = g.pop('db', None)
    if db is not None:
        db.close()

@app.route("/login", methods=["POST", "GET"])
def login():
    if request.method == 'GET':
        return "Expected a POST request", 400

    email = escape(request.form["Email"])
    pswd = escape(request.form["Password"])

    if not validators.email(email):
        return "Invalid Email", 401
    
    db = get_db()
    cur = db.cursor()

    query = "SELECT pswd FROM " + TABLE + " WHERE email=%s"
    cur.execute(query, (email,))
    myres = cur.fetchone()

    if myres == None:
        return {"Detail": "No record"}, 403
    
    key = gen_access_key(username=email).decode()
    
    if str(myres[0]) != str(hashlib.sha512(pswd.encode()).hexdigest()):
        return {"Detail": "Incorrect password"}, 403
        
    return {"ACCESS-KEY": key}, 200

@app.route('/logout', methods=["POST", "GET"])
def logout():
    if request.method == "GET":
        return "Expected POST request", 401
    akey = escape(request.form["ACCESS-KEY"]) or escape(json.loads(request.args.get("headers")["ACCESS-KEY"]))
    if not akey:
        return "No ACCESS-KEY", 403
    akey_dec = base64.b64decode(akey).decode().split('-')
    uname = akey_dec[0]
    rand = int(akey_dec[-1])
    
    AKEYS_GLOBAL[uname].remove(rand)
    
    return {}

# @app.route('/next', methods=["POST", "GET"])
# def next_section():
#     if request.method == "GET":
#         return "Expected a POST request", 400
#     akey = escape(request.form["ACCESS-KEY"])
#     if not akey:
#         return 401, "Missing parameter"

#     user = str(base64.b64decode(akey)).split('-')[0]
    
#     is_valid_akey = validate_akey(akey, user)
#     if not is_valid_akey[0]:
#         return 403, "Invalid ACCESS-KEY"

#     akey = is_valid_akey[-1]["ACCESS-TOKEN"]
#     next_url = get_next_item(user)
#     return next_url

# @app.route("/progress")
# def progress():
#     if request.method == "GET":
#         return "Expected a POST request", 400
#     akey = escape(request.form["ACCESS-KEY"])
#     if not akey:
#         return 401, "Missing parameter"
#     user = str(base64.b64decode(akey)).split('-')[0]
    
#     is_valid_akey = validate_akey(akey, user)
#     if not is_valid_akey[0]:
#         return 403, "Invalid ACCESS-KEY"

#     akey = is_valid_akey[-1]["ACCESS-TOKEN"]
#     progress = get_user_progress(user)
#     return progress

# @app.route('/password-reset', methods=["POST", "GET"])
# def reset_password():
#     if request.method == 'GET':
#         return "Expected a POST request", 400

#     email = escape(request.form["Email"])

#     if not validators.email(email):
#         return 400, "Invalid Email"

#     db = get_db()
#     cur = db.cursor()

#     cur.execute(f"SELECT * FROM ${DBNAME} WHERE email=${email}")
#     if not cur.fetchone():
#         return "Email does not exists", 401

#     cur.close()
#     close_db()

#     # TODO: Handle password reset

#     return 200

