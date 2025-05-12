from flask import Flask, render_template, jsonify
import json

app = Flask(__name__)

@app.route('/')
def home():
    with open('products.json') as f:
        products = json.load(f)
    return render_template('index.html', products=products)

@app.route('/product/<int:product_id>')
def product(product_id):
    with open('products.json') as f:
        products = json.load(f)
    product = next((p for p in products if p["id"] == product_id), None)
    return render_template('product.html', product=product)

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0')

