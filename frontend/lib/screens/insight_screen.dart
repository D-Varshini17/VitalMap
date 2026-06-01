import 'package:flutter/material.dart';

import '../core/responsive.dart';
import '../styles.dart';
import '../widgets/brand_logo.dart';
import '../widgets/organ_visual.dart';

class InsightScreen extends StatelessWidget {
  const InsightScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(title: const BrandAppBarTitle(title: 'VitalMap')),
        body: ResponsiveContainer(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 8),
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
                  style: TextStyle(fontSize: 16, color: AppStyles.muted),
                ),
                const SizedBox(height: 24),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = Responsive.columns(
                      context,
                      mobile: 2,
                      tablet: 3,
                      desktop: 4,
                    );
                    final aspectRatio = switch (columns) {
                      4 => 0.98,
                      3 => 0.88,
                      _ => 0.82,
                    };
                    return GridView.count(
                      crossAxisCount: columns,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      childAspectRatio: aspectRatio,
                      children: [
                        _OrganInsightCard(
                          organName: 'Heart',
                          organKey: 'heart',
                          explanation:
                              'Pumps blood and oxygen throughout the body.',
                          relatedIndex: 'AIP',
                          onTap: () => _openDetail(context, 'Heart'),
                        ),
                        _OrganInsightCard(
                          organName: 'Liver',
                          organKey: 'liver',
                          explanation:
                              'Supports metabolism, detoxification and fat processing.',
                          relatedIndex: 'APRI, FIB-4, FLI, NAFLD',
                          onTap: () => _openDetail(context, 'Liver'),
                        ),
                        _OrganInsightCard(
                          organName: 'Kidney',
                          organKey: 'kidney',
                          explanation:
                              'Filters waste and balances body fluids.',
                          relatedIndex: 'eGFR',
                          onTap: () => _openDetail(context, 'Kidney'),
                        ),
                        _OrganInsightCard(
                          organName: 'Lungs',
                          organKey: 'lungs',
                          explanation:
                              'Exchange oxygen and carbon dioxide for breathing.',
                          relatedIndex: 'SpO₂',
                          onTap: () => _openDetail(context, 'Lungs'),
                        ),
                        _OrganInsightCard(
                          organName: 'Brain / Metabolic',
                          organKey: 'brain',
                          explanation:
                              'Controls metabolism, energy and hormone balance.',
                          relatedIndex: 'TyG',
                          onTap: () =>
                              _openDetail(context, 'Brain / Metabolic'),
                        ),
                        _OrganInsightCard(
                          organName: 'Inflammation',
                          organKey: 'inflammation',
                          explanation:
                              'Body\'s defense system against infections & stress.',
                          relatedIndex: 'NLR',
                          onTap: () => _openDetail(context, 'Inflammation'),
                        ),
                        _OrganInsightCard(
                          organName: 'Pancreas',
                          organKey: 'pancreas',
                          explanation:
                              'Aids digestion and regulates blood sugar.',
                          relatedIndex: 'LAR, TyG',
                          onTap: () => _openDetail(context, 'Pancreas'),
                        ),
                        _OrganInsightCard(
                          organName: 'Cancer Awareness',
                          organKey: 'cancer',
                          explanation:
                              'Tumor markers are awareness indicators only.',
                          relatedIndex: 'AFP, CA 15-3, CA 27.29',
                          onTap: () => _openDetail(context, 'Cancer Awareness'),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),
              ],
            ),
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
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: OrganVisualIcon(organ: organKey, size: 100)),
            const SizedBox(height: 8),
            Text(
              organName,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: AppStyles.navy,
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: Text(
                explanation,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppStyles.muted,
                  height: 1.35,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Related: $relatedIndex',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: AppStyles.primary,
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: onTap,
                style: TextButton.styleFrom(
                  foregroundColor: AppStyles.primary,
                  side: const BorderSide(color: AppStyles.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
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
        howItWorks =
            'The heart is a muscular pump that continuously moves oxygen-rich blood to the brain, kidneys, liver, lungs, muscles, and every other tissue. It works together with blood vessels to maintain circulation and support energy delivery. When blood pressure, lipid balance, smoking exposure, inactivity, or stress are unfavorable for a long time, the heart and blood vessels may need closer monitoring.';
        whyImportant =
            'Heart health is important because circulation supports almost every body function. Healthy blood vessels and balanced lipids help oxygen and nutrients reach tissues efficiently. Poor lipid patterns, excess abdominal fat, smoking, high sugar intake, low activity, and chronic stress can contribute to cardiovascular risk indicators over time.';
        relatedIndexes = 'AIP';
        whatIndexesIndicate =
            'AIP is a lipid-related screening indicator based on the relationship between triglycerides and HDL cholesterol. A higher AIP pattern may suggest that lipid balance is less favorable. It does not diagnose heart disease; it only helps the user understand whether lipid values may need monitoring or clinical discussion.';
        possibleRiskPatterns =
            'Possible concern patterns include high triglycerides with low HDL, high sugar intake, low physical activity, smoking/passive smoking, high stress, obesity pattern, or family history. These patterns may contribute to a higher cardiometabolic screening indicator.';
        howToMaintain =
            'Support heart health by doing regular physical activity, limiting fried and processed foods, reducing sugary drinks, increasing fruits/vegetables, avoiding smoking and passive smoking, sleeping well, managing stress, and reviewing lipid values periodically when advised.';
        whenToConsult =
            'Consult a healthcare professional if you experience chest pain, shortness of breath, or persistent abnormal values.';
        break;
      case 'Liver':
        howItWorks =
            'The liver is a major metabolic organ. It processes nutrients, stores energy, helps regulate fats and glucose, produces important proteins, supports bile production, and breaks down many toxins and chemicals. Because it handles many body processes, lifestyle, alcohol exposure, body weight, glucose levels, and lipid levels can influence liver-related screening indicators.';
        whyImportant =
            'Healthy liver function supports digestion, energy balance, fat handling, detoxification, and blood protein production. Long-term fatty liver patterns, inflammation, alcohol exposure, metabolic imbalance, or persistent abnormal enzymes may require medical review.';
        relatedIndexes = 'APRI, FIB-4, FLI, NAFLD';
        whatIndexesIndicate =
            'APRI and FIB-4 are fibrosis-related screening indicators. FLI and NAFLD score are fatty liver/fibrosis-related screening indicators.';
        possibleRiskPatterns =
            'Lifestyle, alcohol exposure, body weight, glucose, and lipids can influence liver risk indicators.';
        howToMaintain =
            'Maintain liver health through balanced diet, weight management, reduced alcohol exposure, physical activity, and clinical follow-up for persistent abnormal values.';
        whenToConsult =
            'Seek medical advice for unexplained fatigue, yellowing of skin/eyes, or continuous abnormal lab results.';
        break;
      case 'Kidney':
        howItWorks =
            'The kidneys filter waste products from the blood, balance body fluids, regulate electrolytes, and help maintain blood pressure. They also support red blood cell production and acid-base balance. Creatinine and eGFR are commonly used to estimate how efficiently the kidneys filter blood.';
        whyImportant =
            'Kidney health is important because waste and fluid balance affect the whole body. Persistent low filtration indicators can be linked with blood pressure, glucose control, dehydration, kidney stress, or other medical conditions that need clinical interpretation.';
        relatedIndexes = 'eGFR';
        whatIndexesIndicate =
            'eGFR estimates kidney filtration using age, sex, and creatinine.';
        possibleRiskPatterns =
            'Low eGFR may suggest need for monitoring or clinical review.';
        howToMaintain =
            'Maintain kidney health through hydration, BP/glucose control, avoiding unnecessary nephrotoxic medicine use, and regular checkups.';
        whenToConsult =
            'Consult a doctor if you notice changes in urination, swelling, or sustained low eGFR.';
        break;
      case 'Lungs':
        howItWorks =
            'The lungs bring oxygen into the body and remove carbon dioxide. Oxygen moves from air sacs into the blood and is delivered to organs through circulation. SpO₂ is a simple measurement of blood oxygen saturation and can help identify whether oxygen levels appear within an expected screening range.';
        whyImportant =
            'Good lung function supports energy, brain function, exercise capacity, sleep quality, and overall organ health. Smoking, passive smoking, air pollution, dust or chemical exposure, respiratory infections, and chronic breathing symptoms can affect oxygen-related indicators.';
        relatedIndexes = 'SpO₂';
        whatIndexesIndicate = 'SpO₂ reflects blood oxygen saturation levels.';
        possibleRiskPatterns =
            'Low SpO₂ may need monitoring or clinical review, especially with symptoms.';
        howToMaintain =
            'Maintain lung health by avoiding smoking/passive smoke, reducing pollution exposure, staying active, and seeking care for breathing difficulty.';
        whenToConsult =
            'Seek urgent care for severe shortness of breath or persistent low oxygen levels.';
        break;
      case 'Brain / Metabolic':
        howItWorks =
            'Metabolic health describes how the body uses and stores energy, handles glucose, and processes fats. It affects the brain, liver, pancreas, heart, and blood vessels. The TyG index combines fasting glucose and triglycerides to give a screening view of metabolic balance.';
        whyImportant =
            'Metabolic imbalance can influence long-term organ health. High sugar intake, sugary drinks, processed foods, low activity, poor sleep, stress, abdominal weight pattern, and family history can all contribute to less favorable metabolic indicators.';
        relatedIndexes = 'TyG';
        whatIndexesIndicate =
            'TyG uses triglycerides and fasting glucose as a metabolic screening indicator.';
        possibleRiskPatterns =
            'Lifestyle, sugar intake, physical activity, sleep, and stress can influence metabolic risk indicators.';
        howToMaintain =
            'Maintain metabolic health through balanced diet, activity, sleep, and regular glucose/lipid monitoring.';
        whenToConsult =
            'Consult a physician for chronic fatigue, excessive thirst, or persistently abnormal metabolic markers.';
        break;
      case 'Inflammation':
        howItWorks =
            'Inflammation is the body’s protective response to stress, infection, injury, or irritation. White blood cells help coordinate this response. NLR compares neutrophils and lymphocytes and can reflect an inflammatory or physiological stress pattern.';
        whyImportant =
            'Short-term inflammation is normal and helpful, but persistent inflammatory patterns can occur with infections, stress, chronic conditions, smoking exposure, poor sleep, or other triggers. NLR is not disease-specific, so it should be interpreted carefully.';
        relatedIndexes = 'NLR';
        whatIndexesIndicate =
            'NLR uses neutrophils and lymphocytes to reflect inflammatory/physiological stress pattern.';
        possibleRiskPatterns =
            'Elevated NLR can occur in many conditions and is not disease-specific.';
        howToMaintain =
            'Maintain health through infection prevention, sleep, stress management, balanced diet, and clinical review if symptoms persist.';
        whenToConsult =
            'Seek advice if you have ongoing fever, unexplained pain, or persistent elevated markers.';
        break;
      case 'Pancreas':
        howItWorks =
            'The pancreas has two major roles. It produces digestive enzymes such as amylase and lipase, and it helps regulate blood glucose through hormones such as insulin. Pancreatic enzyme patterns and metabolic indicators can provide screening insight when values are available.';
        whyImportant =
            'Pancreatic and metabolic health are important for digestion, glucose balance, and fat handling. High triglycerides, alcohol exposure, abdominal symptoms, and abnormal enzyme values may require clinical interpretation.';
        relatedIndexes = 'LAR, TyG';
        whatIndexesIndicate =
            'LAR uses lipase and amylase pattern as pancreatic enzyme indicator. TyG also supports metabolic/pancreatic risk understanding.';
        possibleRiskPatterns =
            'Elevations may relate to inflammation, duct blockages, or metabolic stress.';
        howToMaintain =
            'Maintain pancreas/metabolic health through balanced food habits, limiting alcohol, controlling triglycerides/glucose, and clinical review for abdominal symptoms.';
        whenToConsult =
            'Seek immediate care for severe abdominal pain or persistent digestive issues.';
        break;
      case 'Cancer Awareness':
        howItWorks =
            'Tumor markers such as AFP, CA 15-3, and CA 27.29 are blood markers that may be used in certain clinical contexts. They are not standalone cancer tests and cannot confirm cancer by themselves. Values can change in benign conditions, inflammation, liver conditions, and other medical situations.';
        whyImportant =
            'Cancer awareness markers should be understood carefully. They may be part of monitoring or follow-up when a clinician requests them, but abnormal values must be reviewed with medical history, examination, imaging, and other tests.';
        relatedIndexes = 'AFP, CA 15-3, CA 27.29';
        whatIndexesIndicate =
            'AFP, CA 15-3, and CA 27.29 can be elevated in benign or serious conditions. These markers do not confirm cancer.';
        possibleRiskPatterns =
            'Possible patterns include marker values outside the expected range, persistent increase over time, or values interpreted alongside symptoms or other findings. These markers can be raised in benign or serious conditions, so the app should only suggest clinical review and must never present the marker as a cancer confirmation.';
        howToMaintain =
            'Maintain awareness through routine screening when advised by clinicians, healthy lifestyle, and timely follow-up.';
        whenToConsult =
            'Abnormal values should always be discussed with a qualified healthcare professional.';
        break;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          organ,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppStyles.navy,
          ),
        ),
        iconTheme: const IconThemeData(color: AppStyles.primary),
      ),
      body: ResponsiveContainer(
        maxWidth: Responsive.detailMaxWidth,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Large organ visual
              Center(
                child: OrganVisualIcon(organ: organ, size: 200, showGlow: true),
              ),
              const SizedBox(height: 12),
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
                    ),
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
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
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
              _infoBlock(
                context,
                '2. Why this organ is important',
                whyImportant,
              ),
              _infoBlock(
                context,
                '3. Related indexes in VitalMap',
                relatedIndexes,
              ),
              _infoBlock(
                context,
                '4. What these indexes generally indicate',
                whatIndexesIndicate,
              ),
              _infoBlock(
                context,
                '5. Possible risk patterns',
                possibleRiskPatterns,
              ),
              _infoBlock(
                context,
                '6. How to maintain proper health',
                howToMaintain,
              ),
              _infoBlock(
                context,
                '7. When to consult a healthcare professional',
                whenToConsult,
              ),
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoBlock(BuildContext context, String title, String content) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: AppStyles.text,
          ),
        ),
        iconColor: AppStyles.primary,
        collapsedIconColor: AppStyles.muted,
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(bottom: 16),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              color: AppStyles.muted,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
