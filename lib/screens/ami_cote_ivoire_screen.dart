import 'package:flutter/material.dart';
import 'package:app_settings/app_settings.dart';

class AmiCoteIvoireScreen extends StatelessWidget {
  const AmiCoteIvoireScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: const Color(0xFFD4A017),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('AMI Côte d\'Ivoire', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () => AppSettings.openAppSettings(),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: const Text(
              '"Allez, faites de toutes les nations des disciples" — Matthieu 28:19',
              style: TextStyle(color: Color(0xFF7A431D), fontSize: 14, fontStyle: FontStyle.italic),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/background.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Logo et titre centrés
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Image.asset('assets/images/logo.png', height: 80),
                        const SizedBox(height: 16),
                        const Text(
                          'Action Missionnaire Interafricaine',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF7A431D)),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Côte d\'Ivoire',
                          style: TextStyle(fontSize: 16, color: Color(0xFFD4A017)),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Présentation
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Présentation de l\'AMI', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFD4A017))),
                        const SizedBox(height: 8),
                        const Text(
                          'Fondée en 1990 à l\'initiative des missionnaires de CAPRO (Calvary Ministries), l\'Action Missionnaire Interafricaine Côte d\'Ivoire (AMI-CI) est une agence missionnaire transculturelle engagée dans l\'accomplissement de la Grande Commission.\n\nAMI-CI travaille en étroite collaboration avec l\'ensemble des dénominations protestantes, évangéliques et pentecôtistes.',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black),
                          textAlign: TextAlign.justify,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Notre Vision
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Notre Vision', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFD4A017))),
                        const SizedBox(height: 8),
                        const Text(
                          'L\'Action Missionnaire Interafricaine (AMI) est née du fardeau d\'atteindre les peuples non atteints de l\'Afrique et du monde par l\'Évangile de Jésus-Christ dans le contexte de leur culture. Cela consiste à susciter un corps de croyants autochtones, autonomes, capables d\'envoyer par eux-mêmes des missionnaires dans le reste du monde.',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black),
                          textAlign: TextAlign.justify,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Nos Objectifs
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Nos Objectifs', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFD4A017))),
                        const SizedBox(height: 8),
                        const Text(
                          '• Rechercher et identifier les peuples non atteints en Afrique et dans le reste du monde.\n'
                          '• Recruter, former et envoyer des missionnaires parmi les peuples non atteints.\n'
                          '• Implanter des églises autochtones, autonomes, capables de s\'autofinancer et de s\'autopropager.\n'
                          '• Aider, à travers la sensibilisation et la mobilisation missionnaire, des programmes d\'enseignement et de discipolat, les églises et le Corps du Christ dans le pays à répondre à l\'Ordre suprême.\n'
                          '• Apporter notre contribution, avec les moyens appropriés, au travail missionnaire en cours dans le pays.',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black),
                          textAlign: TextAlign.justify,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Nos Champs Missionnaires
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Nos Champs Missionnaires', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFD4A017))),
                        const SizedBox(height: 8),
                        const Text(
                          'Un champ missionnaire est un peuple non atteint au sein duquel l\'AMI a envoyé des missionnaires y œuvrer.\n\n'
                          'Dans le monde, AMI/CAPRO travaille parmi plus de 100 peuples non atteints.\n\n'
                          'En Côte d\'Ivoire, nous travaillons parmi les Lobis, les Koulangos, les Lorhons et les Koyakas.',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black),
                          textAlign: TextAlign.justify,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Nos Activités et Programmes
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Nos Activités et Programmes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFD4A017))),
                        const SizedBox(height: 8),
                        const Text(
                          '• La Classe de disciples\n'
                          '• La classe des leaders\n'
                          '• Le RHEMA\n'
                          '• VSD dans sa Présence\n'
                          '• L\'ECOMA : l\'École de Mariage\n'
                          '• École de Ministère (ECOMIN)\n'
                          '• Expédition Missionnaire à Court Terme (EMACT)\n'
                          '• Des Séminaires sur la Mission\n'
                          '• Encadrement des adolescents et des benjamins\n'
                          '• Des Retraites de Prière\n'
                          '• Des Programmes d\'enseignement\n'
                          '• Des activités de prière d\'intercession pour les peuples non atteints\n'
                          '• Des Formations de leaders chrétiens\n'
                          '• Des Formations sur l’évangélisation et sur l\'implantation d\'églises\n'
                          '• Sorties d\'évangélisation\n'
                          '• Service Volontaire Chrétien, etc.',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black),
                          textAlign: TextAlign.justify,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Notre Organisation
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Notre Organisation', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFD4A017))),
                        const SizedBox(height: 8),
                        const Text(
                          'L\'AMI est organisée comme suit :\n'
                          '• Les départements de l\'Administration, de la Mobilisation, de la Formation, de la Recherche et des Finances.\n'
                          '• Les Zones, les Champs Missionnaires et les Cellules.',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black),
                          textAlign: TextAlign.justify,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Nos Ressources
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Nos Ressources', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFD4A017))),
                        const SizedBox(height: 8),
                        const Text(
                          'L\'AMI vit entièrement et totalement par la foi. Elle croit en Dieu pour pourvoir à ses besoins. L\'AMI croit aussi que l\'œuvre du Seigneur se fait en équipe.\n\n'
                          '« Et comment y aura-t-il des prédicateurs, s\'ils ne sont pas envoyés selon qu\'il est écrit : Qu\'ils sont beaux les pieds de ceux qui annoncent la paix, de ceux qui annoncent de bonnes nouvelles ! »\n'
                          '— Romains 10:15\n\n'
                          'Elle compte sur le Seigneur pour pourvoir aux besoins du ministère et à ceux des missionnaires. Ainsi, l\'AMI partage ses besoins avec les chrétiens et les communautés ayant saisi la vision du Seigneur pour les peuples non atteints. C\'est à travers leurs dons volontaires et leur soutien que l\'AMI fonctionne.',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black),
                          textAlign: TextAlign.justify,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Appel à l'engagement
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFD4A017)),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          color: const Color(0xFFD4A017),
                          child: const Text(
                            'Ressentez-vous l\'appel missionnaire ?',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Bureau National de la Mission AMI-CI\n'
                          '08 BP 1818 Abidjan 08, Côte d\'Ivoire\n\n'
                          'Email : amicapro_ci@yahoo.fr\n'
                          'Tél : +225 07 09 65 35 25 / +225 07 09 00 46 21 / +225 07 04 00 98 22',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black),
                          textAlign: TextAlign.justify,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF7A431D),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          ),
                          child: const Text('Rejoignez l\'effort pour faire briller la lumière de l\'Évangile dans les zones les moins atteintes !'),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          '"Allez, faites de toutes les nations des disciples [...] et enseignez-leur à observer tout ce que je vous ai prescrit." — Matthieu 28:19-20',
                          style: TextStyle(fontStyle: FontStyle.italic, fontSize: 14, fontWeight: FontWeight.normal, color: Colors.black),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}