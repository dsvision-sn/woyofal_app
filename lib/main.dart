import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const SenelecPayApp());
}

class SenelecPayApp extends StatelessWidget {
  const SenelecPayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Woyofal Senelec',
      debugShowCheckedModeBanner: false,
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        dragDevices: {
          PointerDeviceKind.touch,
          PointerDeviceKind.mouse,
        },
      ),
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFEF3340),
          surface: const Color(0xFFFDF8F8),
        ),
        scaffoldBackgroundColor: const Color(0xFFFDF8F8),
      ),
      home: const SenelecPayHomePage(),
    );
  }
}

class SenelecPayHomePage extends StatefulWidget {
  const SenelecPayHomePage({super.key});

  @override
  State<SenelecPayHomePage> createState() => _SenelecPayHomePageState();
}

class _SenelecPayHomePageState extends State<SenelecPayHomePage> {
  double _kwhRestants = 5000 / 82.0; // donne 60.97 kWh
  bool _isLoading = true;
  Timer? _timerConsommation;
  String _moyenPaiement = 'Wave';
  String _categorieSelectionnee = 'Tous';
// Liste de vos compteurs enregistrés
 final List<CompteurItem> _mesCompteurs = [
  CompteurItem(nom: 'Maison', numero: '1425364758'),
  CompteurItem(nom: 'Bureau', numero: '1425364759'),
  CompteurItem(nom: 'Appartement', numero: '1425364760'),
  CompteurItem(nom: 'Magasin', numero: '1425364761'),
];

  CompteurItem? _compteurSelectionne;
  final TextEditingController _compteurController = TextEditingController(text: '1425364758');
  final TextEditingController _montantController = TextEditingController(text: '5000');
 
void _verifierSeuilCredit() {
    double seuilAlerte = 15.0; 

    if (_kwhRestants <= seuilAlerte) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Attention : Votre crédit Woyofal est bas ! (${_kwhRestants.toStringAsFixed(1)} kWh restants)',
          ),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }
  Future<void> lancerPaiement({required String montant, required String operateur, required String compteur}) async {
    final url = Uri.parse('https://votre-api-de-paiement.com/api/v1/payment/initiate');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'amount': montant,
          'operator': operateur,
          'meter_number': compteur,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final String paymentUrl = data['redirect_url'];

        final Uri uri = Uri.parse(paymentUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          throw 'Impossible d\'ouvrir le lien de paiement';
        }
      } else {
        print('Erreur lors de l\'initialisation du paiement');
      }
} catch (e) {
      print('Erreur réseau : $e');
    }
  } // <--- Fermeture de la fonction lancerPaiement

  

// --- ÉQUIPEMENTS & ÉTATS ---
  // --- ÉQUIPEMENTS & ÉTATS ---
  // Maison
  bool _climActive = true;
  bool _frigoActif = true;
  bool _tvSalonActive = true;
  bool _tvChambreActive = true;
  bool _ventilateurActif = true;
  bool _eclairageActif = true;

  // Entreprise / Bureau
  bool _pcActif = false;
  bool _imprimanteActive = false;
  bool _serveurActif = false;

  // Restaurant
  bool _congelateurProActif = false;
  bool _machineCafeActive = false;
  bool _microOndesActif = false;
  bool _mixeurActif = false;
  bool _friteuseActive = false;
  bool _plaqueInductionActive = false;

  // Studio
  bool _enceintesStudioActive = false;
  bool _tableMixageActive = false;

  // --- MAP DES CONSOMMATIONS (kWh/jour) ---
  final Map<String, double> _consommationAppareils = {
    // Maison
    'Frigo': 1.8,
    'Clim': 8.0,
    'TV Salon': 1.2,
    'TV Chambre': 0.8,
    'Ventilateur': 0.6,
    'Éclairage': 0.5,

    // Entreprise
    'PC / Ordinateur': 1.5,
    'Imprimante pro': 1.0,
    'Serveur / Switch': 3.0,

    // Restaurant
    'Congélateur pro': 5.0,
    'Machine à café': 4.0,

    // Studio
    'Enceintes Studio': 1.2,
    'Table de mixage': 1.8,

    // Cuisines
    'Micro-ondes': 0.8,
    'Mixeur / Blendor': 0.3,
    'Friteuse / Air Fryer': 1.8,
    'Plaque à induction': 3.5,
  };

  int _calculerJoursTotaux() {
    if (_kwhRestants <= 0) return 0;

    double consoJourTotale = 0.0;

    // Maison
    if (_frigoActif) consoJourTotale += _consommationAppareils['Frigo'] ?? 1.8;
    if (_climActive) consoJourTotale += _consommationAppareils['Clim'] ?? 8.0;
    if (_tvSalonActive) consoJourTotale += _consommationAppareils['TV Salon'] ?? 1.2;
    if (_tvChambreActive) consoJourTotale += _consommationAppareils['TV Chambre'] ?? 0.8;
    if (_ventilateurActif) consoJourTotale += _consommationAppareils['Ventilateur'] ?? 0.6;
    if (_eclairageActif) consoJourTotale += _consommationAppareils['Éclairage'] ?? 0.5;

    // Entreprise
    if (_pcActif) consoJourTotale += _consommationAppareils['PC / Ordinateur'] ?? 1.5;
    if (_imprimanteActive) consoJourTotale += _consommationAppareils['Imprimante pro'] ?? 1.0;
    if (_serveurActif) consoJourTotale += _consommationAppareils['Serveur / Switch'] ?? 3.0;

    // Restaurant
    if (_congelateurProActif) consoJourTotale += _consommationAppareils['Congélateur pro'] ?? 5.0;
    if (_machineCafeActive) consoJourTotale += _consommationAppareils['Machine à café'] ?? 4.0;

    // Studio
    if (_enceintesStudioActive) consoJourTotale += _consommationAppareils['Enceintes Studio'] ?? 1.2;
    if (_tableMixageActive) consoJourTotale += _consommationAppareils['Table de mixage'] ?? 1.8;

    if (consoJourTotale == 0) return 0;

    return (_kwhRestants / consoJourTotale).round();
  }

  // Calcul dynamique des jours d'autonomie par appareil
String _calculerJoursAppareil(String nomAppareil) {
  if (_kwhRestants <= 0) return '0';

  double watts = 100.0;
  double heuresParJour = 24.0;

  switch (nomAppareil) {
    case 'Frigo':
      watts = 150.0;
      heuresParJour = 12.0;
      break;
    case 'Clim':
      watts = 1200.0;
      heuresParJour = 8.0;
      break;
    case 'TV Salon':
    case 'TV Chambre':
      watts = 100.0;
      heuresParJour = 6.0;
      break;
    case 'Ventilateur':
      watts = 60.0;
      heuresParJour = 10.0;
      break;
    case 'Éclairage':
      watts = 50.0;
      heuresParJour = 6.0;
      break;
    case 'Micro-ondes':
      watts = 1200.0;
      heuresParJour = 0.25;
      break;
    case 'Mixeur / Blendour':
      watts = 300.0;
      heuresParJour = 0.1;
      break;
    case 'Imprimante pro':
      watts = 200.0;
      heuresParJour = 1.0;
      break;
    case 'Serveur / Switch':
      watts = 150.0;
      heuresParJour = 24.0;
      break;
    default:
      watts = 100.0;
      heuresParJour = 8.0;
  }

  double consoKwhParJour = (watts * heuresParJour) / 1000.0;
  if (consoKwhParJour == 0) return '0';

  int jours = (_kwhRestants / consoKwhParJour).round();
  return jours.toString();
}

  final List<Map<String, String>> _historique = [
    {
      'montant': '5000 FCFA',
      'details': 'Compteur : 14253647581 (Wave)',
      'code': 'Code : 1928-3746-5019-2837-4650',
      'date': 'Date : 25/08/2026 à 10:15',
    },
    {
      'montant': '10000 FCFA',
      'details': 'Compteur : 14253647581 (Orange Money)',
      'code': 'Code : 4829-1058-9382-0192-8473',
      'date': 'Date : 01/09/2026 à 14:30',
    },
  ];

@override
  void initState() {
    super.initState();
    _chargerSoldeKwh();
    _verifierSeuilCredit(); // <--- Ajoutez cette ligne ici

    _timerConsommation = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _simulerConsommation(),
    );

    if (_mesCompteurs.isNotEmpty) {
      _compteurSelectionne = _mesCompteurs.first;
    }
  }

  @override
  void dispose() {
    _timerConsommation?.cancel();
    _compteurController.dispose();
    _montantController.dispose();
    super.dispose();
  }
void _effectuerRecharge() async {
    if (_moyenPaiement.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner un moyen de paiement'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final montant = _montantController.text.trim();
    if (montant.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez entrer un montant valide'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
// 1. Convertir le montant saisi en nombre
final double montantFcfa = double.tryParse(montant) ?? 0.0;
final double kwhAchetes = montantFcfa / 82.0; // Règle : 1 kWh = 82 FCFA

// 2. Préparer le code USSD selon l'opérateur choisi (_moyenPaiement)
String codeUssd = '';
if (_moyenPaiement == 'Orange Money') {
  codeUssd = '#144#3#1*$montantFcfa#';
} else if (_moyenPaiement == 'Free Money') {
  codeUssd = '#150#3*$montantFcfa#';
} else {
  codeUssd = '#144#';
}

// 3. Lancer l'USSD (fonctionne sur mobile, géré en fallback sur le Web)
final Uri uri = Uri(scheme: 'tel', path: codeUssd.replaceAll('#', '%23'));
if (await canLaunchUrl(uri)) {
  await launchUrl(uri);
}

// 4. Mettre à jour l'état (Solde kWh + Historique instantané)
setState(() {
  _kwhRestants += kwhAchetes;
  
  _historique.insert(0, {
    'montant': '${montantFcfa.toInt()} FCFA',
    'details': 'Compteur : 1425364758 ($_moyenPaiement)',
    'code': 'Code : 1928-3746-5019-2837-4650',
    'date': 'Date : À l\'instant',
  });
});
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Recharge réussie 🎉'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Votre recharge de $montant FCFA via $_moyenPaiement a été effectuée avec succès.'),
              const SizedBox(height: 12),
              const Text('Voici votre code Woyofal :', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '1425-9382-0294-1928',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _montantController.clear();
                setState(() {});
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
Future<void> _chargerSoldeKwh() async {
  final prefs = await SharedPreferences.getInstance();
  setState(() {
    // Récupère la valeur sauvegardée ou met la valeur par défaut (1000 / 82.0) si vide
    _kwhRestants = prefs.getDouble('kwh_restants') ?? (1000 / 82.0);
    _isLoading = false;
  });
}

  Future<void> _sauvegarderSoldeKwh(double nouveauSolde) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('kwh_restants', nouveauSolde);
  }
void _rechargerSolde(double montantFcfa) {
    // Réinitialisation du solde si 0 est saisi
    if (montantFcfa == 0) {
      setState(() {
        _kwhRestants = 0.0;
      });
      _sauvegarderSoldeKwh(_kwhRestants);
      return;
    }

    // Ignore les montants négatifs
    if (montantFcfa < 0) return;

    // Conversion FCFA vers kWh (100 FCFA = 1 kWh)
    const double prixParKwh = 100.0;
    double kwhAchetes = montantFcfa / prixParKwh;

setState(() {
  _kwhRestants += kwhAchetes;
  
  // Ajoutez cette ligne pour insérer la nouvelle recharge tout en haut de l'historique
_historique.insert(0, {
  'montant': '${montantFcfa.toInt()} FCFA',
  'details': 'Compteur : 1425364758',
  'code': 'Code : 1928-3746-5019-2837-4650',
  'date': 'À l\'instant',
});
});
    _sauvegarderSoldeKwh(_kwhRestants);
  }
  void _simulerConsommation() {
    double puissanceTotaleWatts = 0.0;

    // 1. Puissance des appareils actifs (en Watts)
    if (_climActive) puissanceTotaleWatts += 1200.0;     // Clim ~1200W
    if (_frigoActif) puissanceTotaleWatts += 150.0;      // Frigo ~150W
    if (_tvSalonActive) puissanceTotaleWatts += 100.0;   // TV Salon ~100W
    if (_tvChambreActive) puissanceTotaleWatts += 80.0;  // TV Chambre ~80W
    if (_ventilateurActif) puissanceTotaleWatts += 60.0; // Ventilateur ~60W
    if (_eclairageActif) puissanceTotaleWatts += 40.0;   // Ampoules ~40W

    // 2. Calcul des kWh consommés en 10 secondes : (kW) * (10s / 3600s)
    double consoKwhEn10Sec = (puissanceTotaleWatts / 1000.0) * (10 / 3600);

    // 3. Déduction du solde
    if (consoKwhEn10Sec > 0 && _kwhRestants > 0) {
      setState(() {
        _kwhRestants = (_kwhRestants - consoKwhEn10Sec).clamp(0.0, double.infinity);
      });
      
      _sauvegarderSoldeKwh(_kwhRestants);
    }
  }
  void _afficherDialogueEditionKwh() {
    TextEditingController editController =
        TextEditingController(text: _kwhRestants.toStringAsFixed(1));

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Modifier le solde kWh'),
          content: TextField(
            controller: editController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Nouveau solde (kWh)',
              suffixText: 'kWh',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF3340),
                foregroundColor: Colors.white,
              ),
onPressed: () {
                double montant = double.tryParse(editController.text) ?? 0.0;
                _rechargerSolde(montant);
                Navigator.pop(context);
              },
              child: const Text('Valider'),
            ),
          ],
        );
      },
    );
  }

  double _calculerKwhDepuisMontant(double montantFcfa) {
    if (montantFcfa <= 0) return 0.0;
    double t1Max = 150 * 91.0;
    if (montantFcfa <= t1Max) {
      return montantFcfa / 91.0;
    } else {
      return 150.0 + ((montantFcfa - t1Max) / 136.0);
    }
  }



  Widget _buildAppareilCard({
    required IconData icon,
    required String label,
    required String autonomie,
    required bool active,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: active
              ? Colors.white.withOpacity(0.25)
              : Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: active ? Colors.white : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              autonomie,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

@override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFEF3340),
        elevation: 0,
        title: const Text(
          'Woyofal Senelec',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 700),
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: const Color(0xFFEF3340),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withOpacity(0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                InkWell(
                                onTap: _afficherDialogueEditionKwh,
                                  borderRadius: BorderRadius.circular(8),
                                  child: Padding(
                                    padding: const EdgeInsets.all(4.0),
                                    child: Row(
                                      children: [
                                        Text(
                                          '${_kwhRestants.toStringAsFixed(1)} kWh',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 28,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        const Icon(Icons.edit,
                                            color: Colors.white70, size: 20),
                                      ],
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '~ ${_calculerJoursTotaux()} Jours',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: (_kwhRestants / 100.0).clamp(0.0, 1.0),
                                backgroundColor: Colors.white.withOpacity(0.3),
                                color: const Color(0xFF00C853),
                                minHeight: 8,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Autonomie estimée des appareils :',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 12),

                            // --- BARRE DE FILTRES ---
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              child: Row(
                                children: ['Tous', 'Maison', 'Cuisine', 'Bureau', 'Restaurant'].map((cat) {
                                  final isSelected = _categorieSelectionnee == cat;
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8.0),
                                    child: ChoiceChip(
                                      label: Text(cat),
                                      selected: isSelected,
                                      selectedColor: const Color(0xFF00875A),
                                      labelStyle: TextStyle(
                                        color: isSelected ? Colors.white : Colors.black87,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      ),
                                      onSelected: (selected) {
                                        if (selected) {
                                          setState(() => _categorieSelectionnee = cat);
                                        }
                                      },
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),

                            const SizedBox(height: 12),

                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  // --- MAISON ---
                                  if (_categorieSelectionnee == 'Tous' ||
                                      _categorieSelectionnee == 'Maison') ...[
                                    _buildAppareilCard(
                                      icon: Icons.kitchen,
                                      label: 'Frigo',
                                      autonomie: '${_calculerJoursAppareil('Frigo')} j',
                                      active: _frigoActif,
                                      onTap: () => setState(() => _frigoActif = !_frigoActif),
                                    ),
                                    const SizedBox(width: 8),
                                    _buildAppareilCard(
                                      icon: Icons.ac_unit,
                                      label: 'Clim',
                                      autonomie: '${_calculerJoursAppareil('Clim')} j',
                                      active: _climActive,
                                      onTap: () => setState(() => _climActive = !_climActive),
                                    ),
                                    const SizedBox(width: 8),
                                    _buildAppareilCard(
                                      icon: Icons.tv,
                                      label: 'TV Salon',
                                      autonomie: '${_calculerJoursAppareil('TV Salon')} j',
                                      active: _tvSalonActive,
                                      onTap: () => setState(() => _tvSalonActive = !_tvSalonActive),
                                    ),
                                    const SizedBox(width: 8),
                                    _buildAppareilCard(
                                      icon: Icons.tv,
                                      label: 'TV Chambre',
                                      autonomie: '${_calculerJoursAppareil('TV Chambre')} j',
                                      active: _tvChambreActive,
                                      onTap: () => setState(() => _tvChambreActive = !_tvChambreActive),
                                    ),
                                    const SizedBox(width: 8),
                                    _buildAppareilCard(
                                      icon: Icons.air,
                                      label: 'Ventilateur',
                                      autonomie: '${_calculerJoursAppareil('Ventilateur')} j',
                                      active: _ventilateurActif,
                                      onTap: () => setState(() => _ventilateurActif = !_ventilateurActif),
                                    ),
                                    const SizedBox(width: 8),
                                    _buildAppareilCard(
                                      icon: Icons.lightbulb,
                                      label: 'Éclairage',
                                      autonomie: '${_calculerJoursAppareil('Éclairage')} j',
                                      active: _eclairageActif,
                                      onTap: () => setState(() => _eclairageActif = !_eclairageActif),
                                    ),
                                  ],

                                  // --- CUISINE ---
                                  if (_categorieSelectionnee == 'Tous' ||
                                      _categorieSelectionnee == 'Cuisine') ...[
                                    const SizedBox(width: 8),
                                    _buildAppareilCard(
                                      icon: Icons.microwave,
                                      label: 'Micro-ondes',
                                      autonomie: '${_calculerJoursAppareil('Micro-ondes')} j',
                                      active: _microOndesActif,
                                      onTap: () => setState(() => _microOndesActif = !_microOndesActif),
                                    ),
                                    const SizedBox(width: 8),
                                    _buildAppareilCard(
                                      icon: Icons.blender,
                                      label: 'Mixeur / Blendor',
                                      autonomie: '${_calculerJoursAppareil('Mixeur / Blendor')} j',
                                      active: _mixeurActif,
                                      onTap: () => setState(() => _mixeurActif = !_mixeurActif),
                                    ),
                                    const SizedBox(width: 8),
                                    _buildAppareilCard(
                                      icon: Icons.soup_kitchen,
                                      label: 'Friteuse / Air Fryer',
                                      autonomie: '${_calculerJoursAppareil('Friteuse / Air Fryer')} j',
                                      active: _friteuseActive,
                                      onTap: () => setState(() => _friteuseActive = !_friteuseActive),
                                    ),
                                    const SizedBox(width: 8),
                                    _buildAppareilCard(
                                      icon: Icons.countertops,
                                      label: 'Plaque à induction',
                                      autonomie: '${_calculerJoursAppareil('Plaque à induction')} j',
                                      active: _plaqueInductionActive,
                                      onTap: () =>
                                          setState(() => _plaqueInductionActive = !_plaqueInductionActive),
                                    ),
                                  ],

                                  // --- BUREAU ---
                                  if (_categorieSelectionnee == 'Tous' ||
                                      _categorieSelectionnee == 'Bureau') ...[
                                    const SizedBox(width: 8),
                                    _buildAppareilCard(
                                      icon: Icons.computer,
                                      label: 'PC / Ordinateur',
                                      autonomie: '${_calculerJoursAppareil('PC / Ordinateur')} j',
                                      active: _pcActif,
                                      onTap: () => setState(() => _pcActif = !_pcActif),
                                    ),
                                    const SizedBox(width: 8),
                                    _buildAppareilCard(
                                      icon: Icons.print,
                                      label: 'Imprimante pro',
                                      autonomie: '${_calculerJoursAppareil('Imprimante pro')} j',
                                      active: _imprimanteActive,
                                      onTap: () => setState(() => _imprimanteActive = !_imprimanteActive),
                                    ),
                                    const SizedBox(width: 8),
                                    _buildAppareilCard(
                                      icon: Icons.dns,
                                      label: 'Serveur / Switch',
                                      autonomie: '${_calculerJoursAppareil('Serveur / Switch')} j',
                                      active: _serveurActif,
                                      onTap: () => setState(() => _serveurActif = !_serveurActif),
                                    ),
                                  ],

                                  // --- RESTAURANT ---
                                  if (_categorieSelectionnee == 'Tous' ||
                                      _categorieSelectionnee == 'Restaurant') ...[
                                    const SizedBox(width: 8),
                                    _buildAppareilCard(
                                      icon: Icons.kitchen,
                                      label: 'Congélateur pro',
                                      autonomie: '${_calculerJoursAppareil('Congélateur pro')} j',
                                      active: _congelateurProActif,
                                      onTap: () =>
                                          setState(() => _congelateurProActif = !_congelateurProActif),
                                    ),
                                    const SizedBox(width: 8),
                                    _buildAppareilCard(
                                      icon: Icons.local_cafe,
                                      label: 'Machine à café',
                                      autonomie: '${_calculerJoursAppareil('Machine à café')} j',
                                      active: _machineCafeActive,
                                      onTap: () => setState(() => _machineCafeActive = !_machineCafeActive),
                                    ),
                                  ],

                                  // --- STUDIO ---
                                  if (_categorieSelectionnee == 'Tous' ||
                                      _categorieSelectionnee == 'Studio') ...[
                                    const SizedBox(width: 8),
                                    _buildAppareilCard(
                                      icon: Icons.speaker,
                                      label: 'Enceintes Studio',
                                      autonomie: '${_calculerJoursAppareil('Enceintes Studio')} j',
                                      active: _enceintesStudioActive,
                                      onTap: () =>
                                          setState(() => _enceintesStudioActive = !_enceintesStudioActive),
                                    ),
                                    const SizedBox(width: 8),
                                    _buildAppareilCard(
                                      icon: Icons.tune,
                                      label: 'Table de mixage',
                                      autonomie: '${_calculerJoursAppareil('Table de mixage')} j',
                                      active: _tableMixageActive,
                                      onTap: () =>
                                          setState(() => _tableMixageActive = !_tableMixageActive),
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFFBF0F0),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Recharger son compteur',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<CompteurItem>(
  value: _compteurSelectionne,
  decoration: InputDecoration(
    labelText: 'Sélectionner un compteur',
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    filled: true,
    fillColor: const Color(0xFFE8E8E8),
    prefixIcon: const Icon(Icons.electric_meter, color: Colors.black54),
  ),
  items: _mesCompteurs.map((CompteurItem compteur) {
    return DropdownMenuItem<CompteurItem>(
      value: compteur,
      child: Text('${compteur.nom} (${compteur.numero})'),
    );
  }).toList(),
  onChanged: (CompteurItem? nouveauCompteur) {
    setState(() {
      _compteurSelectionne = nouveauCompteur;
    });
  },
), // <-- Ajoutez cette virgule ici
Column(
  children: [
    Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              backgroundColor: _moyenPaiement == 'Wave'
                  ? const Color(0xFFFADBD8)
                  : Colors.white,
              side: BorderSide(
                color: _moyenPaiement == 'Wave'
                    ? Colors.red
                    : Colors.grey.shade300,
              ),
            ),
            onPressed: () => setState(() => _moyenPaiement = 'Wave'),
            icon: Icon(
              Icons.check,
              color: _moyenPaiement == 'Wave'
                  ? Colors.red
                  : Colors.transparent,
              size: 18,
            ),
            label: const Text(
              'Wave',
              style: TextStyle(color: Colors.black87),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              backgroundColor: _moyenPaiement == 'Free Money'
                  ? const Color(0xFFFADBD8)
                  : Colors.white,
              side: BorderSide(
                color: _moyenPaiement == 'Free Money'
                    ? Colors.red
                    : Colors.grey.shade300,
              ),
            ),
            onPressed: () => setState(() => _moyenPaiement = 'Free Money'),
            icon: Icon(
              Icons.check,
              color: _moyenPaiement == 'Free Money'
                  ? Colors.red
                  : Colors.transparent,
              size: 18,
            ),
            label: const Text(
              'Free Money',
              style: TextStyle(color: Colors.black87),
            ),
          ),
        ),
      ],
    ),
    const SizedBox(height: 12),
    Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              backgroundColor: _moyenPaiement == 'Orange Money'
                  ? const Color(0xFFFADBD8)
                  : Colors.white,
              side: BorderSide(
                color: _moyenPaiement == 'Orange Money'
                    ? Colors.red
                    : Colors.grey.shade300,
              ),
            ),
            onPressed: () =>
                setState(() => _moyenPaiement = 'Orange Money'),
            icon: Icon(
              Icons.check,
              color: _moyenPaiement == 'Orange Money'
                  ? Colors.red
                  : Colors.transparent,
              size: 18,
            ),
            label: const Text(
              'Orange Money',
              style: TextStyle(color: Colors.black87),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              backgroundColor: _moyenPaiement == 'Wizall'
                  ? const Color(0xFFFADBD8)
                  : Colors.white,
              side: BorderSide(
                color: _moyenPaiement == 'Wizall'
                    ? Colors.red
                    : Colors.grey.shade300,
              ),
            ),
            onPressed: () => setState(() => _moyenPaiement = 'Wizall'),
            icon: Icon(
              Icons.check,
              color: _moyenPaiement == 'Wizall'
                  ? Colors.red
                  : Colors.transparent,
              size: 18,
            ),
            label: const Text(
              'Wizall',
              style: TextStyle(color: Colors.black87),
            ),
          ),
        ),
      ],
    ),
 ],
    ),
    const SizedBox(height: 12),
                            TextField(
                              controller: _montantController,
                              keyboardType: TextInputType.number,
                              onChanged: (val) => setState(() {}),
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.attach_money,
                                    color: Colors.black54),
                                hintText: 'Montant (FCFA)',
                                filled: true,
                                fillColor: const Color(0xFFF7E8E8),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFEF3340),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                onPressed: _effectuerRecharge,
                                child: const Text(
                                  'RECHARGER',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Historique des recharges',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFEF3340),
                        ),
                      ),
                      const SizedBox(height: 10),
                      ..._historique.map((item) {
                        return Card(
                          elevation: 0,
                          margin: const EdgeInsets.only(bottom: 8),
                          color: const Color(0xFFFBF0F0),
                          child: ListTile(
                            title: Text(
                              item['montant']!,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              '${item['details']}\n${item['code']}',
                            ),
                            trailing: Text(
                              item['date']!,
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.black54,
                              ),
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: 20),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF8E1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFFFE082)),
                        ),
                        padding: const EdgeInsets.all(16.0),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.lightbulb,
                                  color: Color(0xFFF57F17),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Prévention & Astuces Économie',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFF57F17),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 10),
                            Text(
                              '• Réglez votre climatiseur à 24°C pour économiser jusqu’à 25% d’énergie.\n'
                              '• Éteignez les appareils en veille pour prolonger votre crédit Woyofal.\n'
                              '• Privilégiez les ampoules LED à faible consommation.\n'
                              '• Rechargez en début de mois pour bénéficier de la première tranche tarifaire plus avantageuse.',
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}class CompteurItem {
  final String nom;
  final String numero;

  CompteurItem({required this.nom, required this.numero});
}

