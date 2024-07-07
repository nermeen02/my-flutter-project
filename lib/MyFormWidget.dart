import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(MaterialApp(
    home: MyFormWidget(),
  ));
}

class Client {
  final String nom;
  final String prenom;
  final String adresseE;
  final String telephone;
  final String password;

  Client({
    required this.nom,
    required this.prenom,
    required this.adresseE,
    required this.telephone,
    required this.password,
  });

  factory Client.fromJson(Map<String, dynamic> json) {
    return Client(
      nom: json['nom'],
      prenom: json['prenom'],
      adresseE: json['adresseE'],
      telephone: json['telephone'],
      password: json['password'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nom': nom,
      'prenom': prenom,
      'adresseE': adresseE,
      'telephone': telephone,
      'password': password,
    };
  }
}

class MyFormWidget extends StatefulWidget {
  @override
  _MyFormWidgetState createState() => _MyFormWidgetState();
}

class _MyFormWidgetState extends State<MyFormWidget> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nomController;
  late TextEditingController _prenomController;
  late TextEditingController _adresseEController;
  late TextEditingController _telephoneController;
  late TextEditingController _passwordController;

  // Clé pour accéder au ScaffoldMessengerState
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() {
    super.initState();
    _nomController = TextEditingController();
    _prenomController = TextEditingController();
    _adresseEController = TextEditingController();
    _telephoneController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _adresseEController.dispose();
    _telephoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      // Récupération du jeton CSRF
      var csrfResponse = await http.get(Uri.parse('http://192.168.1.12:8000/csrf-token'));
      if (csrfResponse.statusCode == 200) {
        var csrfToken = jsonDecode(csrfResponse.body)['csrf_token'];

        // Création d'un objet Client à partir des données du formulaire
        Client client = Client(
          nom: _nomController.text,
          prenom: _prenomController.text,
          adresseE: _adresseEController.text,
          telephone: _telephoneController.text,
          password: _passwordController.text,
        );

        // Envoi des données au serveur Laravel
        var url = 'http://192.168.1.12:8000/api/client';
        var response = await http.post(
          Uri.parse(url),
          headers: {
            'Content-Type': 'application/json',
            'X-CSRF-TOKEN': csrfToken,
          },
          body: jsonEncode(client.toJson()),
        );

        // Vérification de la réponse
        if (response.statusCode == 201) {
          // Succès : affichage d'un message
          var responseData = jsonDecode(response.body);
          _showSnackBar(responseData['message']);
        } else {
          // Erreur : affichage du corps de la réponse JSON
          var errorData = jsonDecode(response.body);
          _showSnackBar('Erreur lors de la soumission du formulaire: ${errorData['message']}');
        }
      } else {
        _showSnackBar('Erreur lors de la récupération du jeton CSRF');
      }
    }
  }

  void _showSnackBar(String message) {
    _scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldMessengerKey, // Utilisation de la clé ScaffoldMessenger
      appBar: AppBar(
        title: Text('Formulaire Client'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nomController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez saisir un nom';
                  }
                  return null;
                },
                decoration: InputDecoration(labelText: 'Nom'),
              ),
              TextFormField(
                controller: _prenomController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez saisir un prénom';
                  }
                  return null;
                },
                decoration: InputDecoration(labelText: 'Prénom'),
              ),
              TextFormField(
                controller: _adresseEController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez saisir une adresse email';
                  }
                  return null;
                },
                decoration: InputDecoration(labelText: 'Adresse Email'),
              ),
              TextFormField(
                controller: _telephoneController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez saisir un numéro de téléphone';
                  }
                  return null;
                },
                decoration: InputDecoration(labelText: 'Téléphone'),
              ),
              TextFormField(
                controller: _passwordController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez saisir un mot de passe';
                  }
                  return null;
                },
                decoration: InputDecoration(labelText: 'Mot de passe'),
                obscureText: true,
              ),
              SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: _submitForm,
                child: Text('Soumettre'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
