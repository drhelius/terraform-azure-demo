from flask import Flask
import os
import socket

app = Flask(__name__)

@app.route('/')
def hello():
    return '<style type="text/css">h1 { color: DodgerBlue; }</style><h1>Hello World from host \"%s\".</h1>\n' % socket.gethostname()

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080, debug=True)
