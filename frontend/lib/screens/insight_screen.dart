import 'package:flutter/material.dart';
import '../styles.dart';
import '../widgets/brand_logo.dart';
import '../widgets/organ_visual.dart';

class InsightScreen extends StatelessWidget {
  const InsightScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const BrandAppBarTitle(title: 'VitalMap'),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Insight',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppStyles.navy,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Understand your body, organs, and screening indicators.',
                style: TextStyle(
                  fontSize: 16,
                  color: AppStyles.muted,
                ),
              ),
              const SizedBox(height: 24),
              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 0.60,
                children: [
                  _OrganInsightCard(
                    organName: 'Heart',
                    organKey: 'heart',
                    explanation: 'Pumps blood and oxygen throughout the body.',
                    relatedIndex: 'AIP',
                    onTap: () => _openDetail(context, 'Heart'),
                  ),
                  _OrganInsightCard(
                    organName: 'Liver',
                    organKey: 'liver',
                    explanation: 'Supports metabolism, detoxification and fat processing.',
                    relatedIndex: 'APRI, FIB-4, FLI, NAFLD',
                    onTap: () => _openDetail(context, 'Liver'),
                  ),
                  _OrganInsightCard(
                    organName: 'Kidney',
                    organKey: 'kidney',
                    explanation: 'Filters waste and balances body fluids.',
                    relatedIndex: 'eGFR',
                    onTap: () => _openDetail(context, 'Kidney'),
                  ),
                  _OrganInsightCard(
                    organName: 'Lungs',
                    organKey: 'lungs',
                    explanation: 'Exchange oxygen and carbon dioxide for breathing.',
                    relatedIndex: 'SpO₂',
                    onTap: () => _openDetail(context, 'Lungs'),
                  ),
                  _OrganInsightCard(
                    organName: 'Brain / Metabolic',
                    organKey: 'brain',
                    explanation: 'Controls metabolism, energy and hormone balance.',
                    relatedIndex: 'TyG',
                    onTap: () => _openDetail(context, 'Brain / Metabolic'),
                  ),
                  _OrganInsightCard(
                    organName: 'Inflammation',
                    organKey: 'inflammation',
                    explanation: 'Body\'s defense system against infections & stress.',
                    relatedIndex: 'NLR',
                    onTap: () => _openDetail(context, 'Inflammation'),
                  ),
                  _OrganInsightCard(
                    organName: 'Pancreas',
                    organKey: 'pancreas',
                    explanation: 'Aids digestion and regulates blood sugar.',
                    relatedIndex: 'LAR, TyG',
                    onTap: () => _openDetail(context, 'Pancreas'),
                  ),
                  _OrganInsightCard(
                    organName: 'Cancer Awareness',
                    organKey: 'cancer',
                    explanation: 'Tumor markers are awareness indicators only.',
                    relatedIndex: 'AFP, CA 15-3, CA 27.29',
                    onTap: () => _openDetail(context, 'Cancer Awareness'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  void _openDetail(BuildContext context, String organ) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => OrganEducationScreen(organ: organ)),
    );
  }
}

class _OrganInsightCard extends StatelessWidget {
  final String organName;
  final String organKey;
  final String explanation;
  final String relatedIndex;
  final VoidCallback onTap;

  const _OrganInsightCard({
    required this.organName,
    required this.organKey,
    required this.explanation,
    required this.relatedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppStyles.border),
          boxShadow: [
            BoxShadow(
              color: AppStyles.navy.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: OrganVisualIcon(organ: organKey, size: 64),
            ),
            const SizedBox(height: 8),
            Text(
              organName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppStyles.navy),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: Text(
                explanation,
                style: const TextStyle(fontSize: 11, color: AppStyles.muted, height: 1.35),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Related: $relatedIndex',
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppStyles.primary),
            ),
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: onTap,
                style: TextButton.styleFrom(
                  foregroundColor: AppStyles.primary,
                  side: const BorderSide(color: AppStyles.border),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  minimumSize: const Size(double.infinity, 32),
                ),
                child: const Text('Learn More', style: TextStyle(fontSize: 11)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OrganEducationScreen extends StatelessWidget {
  final String organ;
  const OrganEducationScreen({super.key, required this.organ});

  @override
  Widget build(BuildContext context) {
    String howItWorks = '';
    String whyImportant = '';
    String relatedIndexes = '';
    String whatIndexesIndicate = '';
    String possibleRiskPatterns = '';
    String howToMaintain = '';
    String whenToConsult = '';

    switch (organ) {
      case 'Heart':
        howItWorks = 'The heart pumps blood and oxygen throughout the body.';
        whyImportant = 'Lipid balance affects cardiovascular health and overall vitality.';
        relatedIndexes = 'AIP';
        whatIndexesIndicate = 'AIP uses triglycerides and HDL pattern to reflect cardiometabolic health.';
        possibleRiskPatterns = 'Unfavorable lipid pattern may suggest cardiometabolic risk.';
        howToMaintain = 'Maintain heart health through regular activity, balanced diet, avoiding smoking, managing stress, and routine checkups.';
        whenToConsult = 'Consult a healthcare professional if you experience chest pain, shortness of breath, or persistent abnormal values.';
        break;
      case 'Liver':
        howItWorks = 'The liver performs over 500 vital functions including metabolism, detoxification, and fat processing.';
        whyImportant = 'It is essential for filtering blood, producing proteins, and managing energy.';
        relatedIndexes = 'APRI, FIB-4, FLI, NAFLD';
        whatIndexesIndicate = 'APRI and FIB-4 are fibrosis-related screening indicators. FLI and NAFLD score are fatty liver/fibrosis-related screening indicators.';
        possibleRiskPatterns = 'Lifestyle, alcohol exposure, body weight, glucose, and lipids can influence liver risk indicators.';
        howToMaintain = 'Maintain liver health through balanced diet, weight management, reduced alcohol exposure, physical activity, and clinical follow-up for persistent abnormal values.';
        whenToConsult = 'Seek medical advice for unexplained fatigue, yellowing of skin/eyes, or continuous abnormal lab results.';
        break;
      case 'Kidney':
        howItWorks = 'Kidneys filter waste, balance fluids, and support blood pressure regulation.';
        whyImportant = 'They are crucial for removing toxins and maintaining mineral balance.';
        relatedIndexes = 'eGFR';
        whatIndexesIndicate = 'eGFR estimates kidney filtration using age, sex, and creatinine.';
        possibleRiskPatterns = 'Low eGFR may suggest need for monitoring or clinical review.';
        howToMaintain = 'Maintain kidney health through hydration, BP/glucose control, avoiding unnecessary nephrotoxic medicine use, and regular checkups.';
        whenToConsult = 'Consult a doctor if you notice changes in urination, swelling, or sustained low eGFR.';
        break;
      case 'Lungs':
        howItWorks = 'Lungs exchange oxygen and carbon dioxide.';
        whyImportant = 'They provide the necessary oxygen for all cellular functions.';
        relatedIndexes = 'SpO₂';
        whatIndexesIndicate = 'SpO₂ reflects blood oxygen saturation levels.';
        possibleRiskPatterns = 'Low SpO₂ may need monitoring or clinical review, especially with symptoms.';
        howToMaintain = 'Maintain lung health by avoiding smoking/passive smoke, reducing pollution exposure, staying active, and seeking care for breathing difficulty.';
        whenToConsult = 'Seek urgent care for severe shortness of breath or persistent low oxygen levels.';
        break;
      case 'Brain / Metabolic':
        howItWorks = 'Metabolic health affects energy use, glucose balance, and long-term organ function.';
        whyImportant = 'It influences brain health, hormonal balance, and systemic wellbeing.';
        relatedIndexes = 'TyG';
        whatIndexesIndicate = 'TyG uses triglycerides and fasting glucose as a metabolic screening indicator.';
        possibleRiskPatterns = 'Lifestyle, sugar intake, physical activity, sleep, and stress can influence metabolic risk indicators.';
        howToMaintain = 'Maintain metabolic health through balanced diet, activity, sleep, and regular glucose/lipid monitoring.';
        whenToConsult = 'Consult a physician for chronic fatigue, excessive thirst, or persistently abnormal metabolic markers.';
        break;
      case 'Inflammation':
        howItWorks = 'Inflammation is part of the body’s defense system.';
        whyImportant = 'It responds to injury or infection but chronic inflammation can cause harm.';
        relatedIndexes = 'NLR';
        whatIndexesIndicate = 'NLR uses neutrophils and lymphocytes to reflect inflammatory/physiological stress pattern.';
        possibleRiskPatterns = 'Elevated NLR can occur in many conditions and is not disease-specific.';
        howToMaintain = 'Maintain health through infection prevention, sleep, stress management, balanced diet, and clinical review if symptoms persist.';
        whenToConsult = 'Seek advice if you have ongoing fever, unexplained pain, or persistent elevated markers.';
        break;
      case 'Pancreas':
        howItWorks = 'The pancreas supports digestion and blood glucose regulation.';
        whyImportant = 'It produces vital enzymes for digestion and insulin for sugar control.';
        relatedIndexes = 'LAR, TyG';
        whatIndexesIndicate = 'LAR uses lipase and amylase pattern as pancreatic enzyme indicator. TyG also supports metabolic/pancreatic risk understanding.';
        possibleRiskPatterns = 'Elevations may relate to inflammation, duct blockages, or metabolic stress.';
        howToMaintain = 'Maintain pancreas/metabolic health through balanced food habits, limiting alcohol, controlling triglycerides/glucose, and clinical review for abdominal symptoms.';
        whenToConsult = 'Seek immediate care for severe abdominal pain or persistent digestive issues.';
        break;
      case 'Cancer Awareness':
        howItWorks = 'Tumor markers are awareness indicators only.';
        whyImportant = 'They can be used alongside other clinical tests to monitor specific health conditions.';
        relatedIndexes = 'AFP, CA 15-3, CA 27.29';
        whatIndexesIndicate = 'AFP, CA 15-3, and CA 27.29 can be elevated in benign or serious conditions. These markers do not confirm cancer.';
        possibleRiskPatterns = 'Abnormal values can result from inflammation, benign tumors, or malignancies.';
        howToMaintain = 'Maintain awareness through routine screening when advised by clinicians, healthy lifestyle, and timely follow-up.';
        whenToConsult = 'Abnormal values should always be discussed with a qualified healthcare professional.';
        break;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(organ, style: const TextStyle(fontWeight: FontWeight.bold, color: AppStyles.navy)),
        iconTheme: const IconThemeData(color: AppStyles.primary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppStyles.border),
                boxShadow: [
                  BoxShadow(
                    color: AppStyles.navy.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  OrganVisualIcon(organ: organ, size: 80, showGlow: true),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          organ,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppStyles.navy,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          howItWorks,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppStyles.text,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppStyles.softBlue,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Related: $relatedIndexes',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppStyles.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Accordion sections
            _infoBlock(context, '1. How this organ works', howItWorks),
            _infoBlock(context, '2. Why this organ is important', whyImportant),
            _infoBlock(context, '3. Related indexes in VitalMap', relatedIndexes),
            _infoBlock(context, '4. What these indexes generally indicate', whatIndexesIndicate),
            _infoBlock(context, '5. Possible risk patterns', possibleRiskPatterns),
            _infoBlock(context, '6. How to maintain proper health', howToMaintain),
            _infoBlock(context, '7. When to consult a healthcare professional', whenToConsult),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F7FA),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppStyles.border),
              ),
              child: const Row(
                children: [
                  Icon(Icons.shield_outlined, color: AppStyles.muted),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Safety disclaimer\nThe information here is for awareness and educational purposes only. It does not replace professional medical advice, diagnosis, or treatment.',
                      style: TextStyle(fontSize: 12, color: AppStyles.muted),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _infoBlock(BuildContext context, String title, String content) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppStyles.text)),
        iconColor: AppStyles.primary,
        collapsedIconColor: AppStyles.muted,
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(bottom: 16),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(content, style: const TextStyle(fontSize: 14, color: AppStyles.muted, height: 1.4)),
        ],
      ),
    );
  }
}
