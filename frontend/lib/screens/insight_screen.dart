import 'package:flutter/material.dart';

import '../core/responsive.dart';
import '../widgets/brand_logo.dart';
import '../widgets/organ_visual.dart';

class InsightScreen extends StatelessWidget {
  const InsightScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);
    return Scaffold(
      appBar: isDesktop
          ? null
          : AppBar(title: const BrandAppBarTitle(title: 'VitalMap')),
      body: ResponsivePage(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Insight',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Understand your body, organs, and screening indicators.',
              style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = Responsive.columns(
                  context,
                  mobile: 1,
                  tablet: 2,
                  desktop: 4,
                );
                final width =
                    (constraints.maxWidth - (12 * (columns - 1))) / columns;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (final card in [
                      _OrganInsightCard(
                        organName: 'Heart',
                        organKey: 'heart',
                        relatedIndex: 'AIP',
                        onTap: () => _openDetail(context, 'Heart'),
                      ),
                      _OrganInsightCard(
                        organName: 'Liver',
                        organKey: 'liver',
                        relatedIndex: 'APRI, FIB-4, FLI, NAFLD',
                        onTap: () => _openDetail(context, 'Liver'),
                      ),
                      _OrganInsightCard(
                        organName: 'Kidney',
                        organKey: 'kidney',
                        relatedIndex: 'eGFR',
                        onTap: () => _openDetail(context, 'Kidney'),
                      ),
                      _OrganInsightCard(
                        organName: 'Lungs',
                        organKey: 'lungs',
                        relatedIndex: 'SpO₂',
                        onTap: () => _openDetail(context, 'Lungs'),
                      ),
                      _OrganInsightCard(
                        organName: 'Brain / Metabolic',
                        organKey: 'brain',
                        relatedIndex: 'TyG',
                        onTap: () => _openDetail(context, 'Brain / Metabolic'),
                      ),
                      _OrganInsightCard(
                        organName: 'Inflammation',
                        organKey: 'inflammation',
                        relatedIndex: 'NLR',
                        onTap: () => _openDetail(context, 'Inflammation'),
                      ),
                      _OrganInsightCard(
                        organName: 'Pancreas',
                        organKey: 'pancreas',
                        relatedIndex: 'LAR, TyG',
                        onTap: () => _openDetail(context, 'Pancreas'),
                      ),
                      _OrganInsightCard(
                        organName: 'Cancer Awareness',
                        organKey: 'cancer',
                        relatedIndex: 'AFP, CA 15-3, CA 27.29',
                        onTap: () => _openDetail(context, 'Cancer Awareness'),
                      ),
                    ])
                      SizedBox(width: width, child: card),
                  ],
                );
              },
            ),
          ],
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
  final String relatedIndex;
  final VoidCallback onTap;

  const _OrganInsightCard({
    required this.organName,
    required this.organKey,
    required this.relatedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(22),
          border:
              Border.all(color: Theme.of(context).colorScheme.outlineVariant),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.outlineVariant,
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: OrganVisualIcon(
                organ: organKey,
                size: Responsive.isDesktop(context) ? 170 : 148,
                showGlow: true,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              organName,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Related: $relatedIndex',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: onTap,
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.primary,
                  side: BorderSide(
                      color: Theme.of(context).colorScheme.outlineVariant),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  minimumSize: const Size(double.infinity, 32),
                ),
                child: const Text(
                  'Learn More',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
                ),
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
    String lifestyleTips = '';
    String foodTips = '';
    String environmentTips = '';
    String whenToConsult = '';
    String keyFunctions = '';
    String whatResultsSuggest = '';
    String nutritionRecommendations = '';
    String referenceRanges = '';
    String healthTips = '';
    String personalizedSummary = '';

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
        lifestyleTips =
            'Support heart health with regular walking or moderate activity, consistent sleep, stress management, and avoidance of smoking or passive smoking.';
        foodTips =
            'Prefer vegetables, fruits, whole grains, lean protein, and unsaturated fats. Limit sugary drinks, high-salt packaged foods, and frequent fried or processed food.';
        environmentTips =
            'Reduce smoke exposure and use ventilation in dusty, polluted, or cooking-smoke environments when practical.';
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
        lifestyleTips =
            'Maintain liver health through regular physical activity, weight management when needed, reduced alcohol exposure, and routine follow-up for persistent abnormal values.';
        foodTips =
            'Choose balanced meals with fiber-rich foods, lean proteins, and fewer sugary drinks or fried foods. Avoid extreme diets unless guided by a clinician.';
        environmentTips =
            'Use protective practices around chemicals, solvents, or workplace exposures, and avoid unnecessary toxin exposure where possible.';
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
        lifestyleTips =
            'Maintain kidney health through steady hydration, regular activity, blood pressure/glucose monitoring when advised, and routine checkups.';
        foodTips =
            'Keep high-salt packaged foods occasional and discuss major protein, potassium, or fluid restrictions with a qualified professional before changing your diet.';
        environmentTips =
            'Avoid dehydration during heat exposure and review workplace chemical exposures or over-the-counter medicine use with a clinician when relevant.';
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
        lifestyleTips =
            'Maintain lung health by avoiding smoking and passive smoke, staying active as tolerated, practicing good sleep habits, and seeking care for breathing difficulty.';
        foodTips =
            'A balanced diet with fruits, vegetables, and enough fluids can support general respiratory wellness. Food choices do not replace clinical care for breathing symptoms.';
        environmentTips =
            'Reduce pollution, dust, chemical, and cooking-smoke exposure where practical. Use ventilation and consider air-quality alerts during high pollution periods.';
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
        lifestyleTips =
            'Maintain metabolic health through regular activity, healthy sleep duration, stress control, and routine glucose/lipid monitoring when advised.';
        foodTips =
            'Limit sugary drinks and frequent refined carbohydrates. Prefer fiber-rich foods, vegetables, whole grains, and balanced portions.';
        environmentTips =
            'Reduce environments that make healthy routines difficult where possible, such as poor sleep settings, smoke exposure, or limited safe activity spaces.';
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
        lifestyleTips =
            'Support balanced immune response with sleep, stress management, activity as tolerated, and infection-prevention habits.';
        foodTips =
            'A varied diet with fruits, vegetables, protein, and adequate hydration supports general wellness. Avoid using one CBC ratio to self-diagnose inflammation.';
        environmentTips =
            'Limit smoke, dust, chemical, and poor air exposure when practical, especially if symptoms are present.';
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
        lifestyleTips =
            'Support pancreas and metabolic health by limiting alcohol, staying active, and monitoring triglyceride or glucose values when advised.';
        foodTips =
            'Prefer balanced meals and reduce frequent fried foods, sugary drinks, and very high-fat meals if these are common habits.';
        environmentTips =
            'Reduce smoke exposure and avoid unsafe chemical exposures where practical. Environmental steps support general health but do not interpret enzyme values alone.';
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
        lifestyleTips =
            'Maintain awareness through clinician-recommended routine screening, healthy sleep, physical activity, and timely follow-up for persistent unusual values.';
        foodTips =
            'A balanced diet supports general health, but food choices cannot confirm or rule out cancer. Discuss marker results with a qualified professional.';
        environmentTips =
            'Reduce tobacco smoke and avoid unsafe chemical exposures where practical. Occupational or environmental concerns should be discussed during clinical review.';
        whenToConsult =
            'Abnormal values should always be discussed with a qualified healthcare professional.';
        break;
    }

    keyFunctions = _keyFunctionsFor(organ);
    whatResultsSuggest = _resultsSuggestFor(organ);
    nutritionRecommendations = _nutritionFor(organ);
    referenceRanges = _referenceRangesFor(organ);
    healthTips = _healthTipsFor(organ);
    personalizedSummary = _personalizedSummaryFor(organ);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          organ,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        iconTheme: IconThemeData(color: Theme.of(context).colorScheme.primary),
      ),
      body: ResponsivePage(
        maxWidth: Responsive.detailMaxWidth,
        topPadding: 16,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: OrganVisualIcon(
                organ: organ,
                size: Responsive.isDesktop(context) ? 180 : 158,
                showGlow: true,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.outlineVariant,
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
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          howItWorks,
                          style: TextStyle(
                            fontSize: 13,
                            color: Theme.of(context).colorScheme.onSurface,
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
                            color:
                                Theme.of(context).colorScheme.surfaceContainer,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Related: $relatedIndexes',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
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
            _infoBlock(context, 'Organ Overview', howItWorks),
            _infoBlock(context, 'Why It Matters', whyImportant),
            _infoBlock(context, 'Key Functions', keyFunctions),
            _infoBlock(context, 'Possible Risk Factors', possibleRiskPatterns),
            _infoBlock(
              context,
              'What Your Results Suggest',
              whatResultsSuggest,
            ),
            _infoBlock(context, 'Lifestyle Suggestions', lifestyleTips),
            _infoBlock(
              context,
              'Nutrition Recommendations',
              '$foodTips\n\n$nutritionRecommendations',
            ),
            _infoBlock(
              context,
              'When To Seek Medical Advice',
              whenToConsult,
            ),
            _infoBlock(
              context,
              'Related Screening Indexes',
              '$relatedIndexes\n\n$whatIndexesIndicate',
            ),
            _infoBlock(context, 'Reference Ranges', referenceRanges),
            _infoBlock(context, 'Health Tips', healthTips),
            _infoBlock(
              context,
              'Environment And Exposure Notes',
              environmentTips,
            ),
            _infoBlock(
              context,
              'Personalized Summary',
              personalizedSummary,
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant),
              ),
              child: Row(
                children: [
                  Icon(Icons.shield_outlined,
                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Safety disclaimer\nFor informational purposes only. This app is not a substitute for clinical diagnosis, treatment, or medical advice. Please consult a qualified healthcare professional for medical decisions.',
                      style: TextStyle(
                          fontSize: 12,
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _keyFunctionsFor(String organ) {
    switch (organ) {
      case 'Heart':
        return 'The heart maintains circulation, supports blood pressure, and delivers oxygen and nutrients through the vascular system. Healthy vessels, flexible arteries, and favorable lipid balance help reduce strain on the pumping system. VitalMap connects this organ mainly with lipid and metabolic screening patterns.';
      case 'Liver':
        return 'The liver processes nutrients, stores glycogen, produces bile, helps regulate fats, builds blood proteins, and breaks down many chemicals. It also participates in glucose control and inflammation response. Because it handles so many metabolic tasks, liver indicators often reflect both report values and daily habits.';
      case 'Kidney':
        return 'The kidneys filter waste, balance water, regulate sodium and potassium, support blood pressure control, and contribute to red blood cell signaling. Creatinine and eGFR give a screening estimate of filtration, but hydration, muscle mass, age, medicines, and medical history can affect interpretation.';
      case 'Lungs':
        return 'The lungs move oxygen into the blood and remove carbon dioxide. They support sleep quality, exercise tolerance, brain function, and every organ that depends on oxygen delivery. SpO2 is a simple oxygen-saturation snapshot, not a full lung-function test.';
      case 'Brain / Metabolic':
        return 'Metabolic health influences brain energy, insulin signaling, blood vessel health, hunger regulation, and long-term organ resilience. Glucose and triglyceride patterns can suggest how smoothly the body is managing fuel. VitalMap uses TyG as a screening lens, not as a diagnosis.';
      case 'Inflammation':
        return 'Inflammation coordinates immune defense, healing, and response to stress. Neutrophils and lymphocytes are white blood cell groups that can shift during infection, stress, poor sleep, smoking exposure, or other triggers. NLR is broad and must be interpreted with context.';
      case 'Pancreas':
        return 'The pancreas supports digestion through enzymes and helps regulate blood glucose through hormones. Lipase and amylase are enzyme markers, while metabolic indicators give additional context. Enzyme patterns can change for many reasons and should not be interpreted alone.';
      case 'Cancer Awareness':
        return 'Cancer awareness markers such as AFP, CA 15-3, and CA 27.29 are specialized blood values used only in certain clinical contexts. They can be influenced by benign and serious conditions. VitalMap treats these as awareness prompts for discussion, never as cancer detection.';
      default:
        return 'This organ supports multiple body systems, and screening values should be read as context rather than diagnosis.';
    }
  }

  String _resultsSuggestFor(String organ) {
    switch (organ) {
      case 'Heart':
        return 'If your calculated AIP is reassuring, the available triglyceride and HDL pattern looks favorable in this screening context. If it is marked monitor or attention, it may mean lipid balance deserves follow-up, especially when paired with smoking, low activity, abdominal weight pattern, high sugar intake, or family history.';
      case 'Liver':
        return 'Liver-related indexes can suggest whether available enzyme, platelet, albumin, glucose, weight, and waist values look reassuring or need monitoring. A raised screening score does not prove liver disease. It means the pattern should be reviewed with medical history, symptoms, alcohol exposure, and clinician-ordered tests.';
      case 'Kidney':
        return 'An eGFR result gives a filtration estimate from creatinine, age, and sex. A reassuring value is helpful, while a lower value should be interpreted with hydration status, repeat testing, urine tests, blood pressure, glucose history, and clinician guidance.';
      case 'Lungs':
        return 'SpO2 in the expected range can be reassuring at the time measured. A low value, repeated dips, or low oxygen with breathlessness should be taken seriously. SpO2 does not explain the cause, so symptoms and clinical evaluation matter.';
      case 'Brain / Metabolic':
        return 'TyG links fasting glucose and triglycerides into a metabolic screening pattern. A higher value can suggest less favorable fuel handling and may be influenced by diet, sleep, stress, activity, waist pattern, and family history. It does not diagnose diabetes or insulin resistance.';
      case 'Inflammation':
        return 'NLR can rise during many normal and abnormal body states, including acute illness, stress, poor sleep, smoking exposure, and inflammation. A single NLR value is not disease-specific. Persistent or symptomatic changes should be reviewed clinically.';
      case 'Pancreas':
        return 'LAR compares lipase and amylase patterns. Unusual enzyme values can occur for several digestive, metabolic, or temporary reasons. Severe abdominal pain, vomiting, fever, or persistent abnormalities require medical evaluation rather than app-based interpretation.';
      case 'Cancer Awareness':
        return 'An awareness marker outside an expected range is a reason to speak with a qualified professional, not a reason to conclude cancer. These markers need clinical context, repeat trends, examination, imaging, and other tests when a clinician decides they are appropriate.';
      default:
        return 'Your result should be treated as a screening explanation that helps organize follow-up questions for a qualified healthcare professional.';
    }
  }

  String _nutritionFor(String organ) {
    switch (organ) {
      case 'Heart':
        return 'Build meals around vegetables, fruit, pulses or lean protein, whole grains, nuts or seeds, and unsaturated fats. Keep trans fats, frequent fried foods, sugar-sweetened drinks, and high-salt packaged foods occasional. Small consistent changes are usually more useful than short extreme plans.';
      case 'Liver':
        return 'A liver-supportive pattern usually emphasizes fiber-rich foods, vegetables, moderate portions, enough protein, and fewer sugary drinks or refined carbohydrates. Alcohol reduction is important when relevant. Avoid supplements or detox plans unless a clinician has confirmed they are safe for you.';
      case 'Kidney':
        return 'For general kidney wellness, keep hydration steady and reduce frequent high-salt packaged foods. Do not start strict protein, potassium, phosphorus, or fluid restriction without medical advice, because needs vary widely by kidney function, medicines, and lab results.';
      case 'Lungs':
        return 'Nutrition cannot replace respiratory care, but balanced meals, adequate protein, fruits, vegetables, and hydration support general resilience. If reflux worsens breathing symptoms, discuss meal timing and trigger foods with a clinician.';
      case 'Brain / Metabolic':
        return 'Prioritize fiber, protein with meals, whole grains, vegetables, and fewer sugary beverages. Pair carbohydrates with protein or healthy fat to reduce sharp glucose swings. Regular meal timing, sleep, and activity often matter as much as any single food.';
      case 'Inflammation':
        return 'A varied pattern with vegetables, fruits, legumes, whole grains, protein, and omega-3 rich foods can support general inflammatory balance. Avoid interpreting one ratio as proof that a special diet is required.';
      case 'Pancreas':
        return 'Limit heavy alcohol exposure and frequent very high-fat meals if they are part of your routine. Choose balanced portions, fiber-rich foods, and steady hydration. Enzyme abnormalities should guide a medical conversation, not a self-directed restrictive diet.';
      case 'Cancer Awareness':
        return 'No food can confirm, rule out, or treat cancer. A balanced diet supports overall health during routine screening and follow-up. Discuss supplements, fasting plans, or major dietary changes with a clinician, especially if markers are being monitored.';
      default:
        return 'A balanced, sustainable eating pattern supports general health and should be personalized with medical guidance when lab results are abnormal.';
    }
  }

  String _referenceRangesFor(String organ) {
    switch (organ) {
      case 'Heart':
        return 'AIP interpretation varies by population and lab context, but lower values are generally more reassuring than higher values. Triglycerides and HDL should be compared with the reference ranges printed on your report and interpreted with cardiovascular risk factors.';
      case 'Liver':
        return 'AST, ALT, GGT, albumin, and platelet reference ranges differ by laboratory. APRI, FIB-4, FLI, and NAFLD-related cutoffs are screening thresholds, not final diagnoses. Trends over time are often more useful than one isolated result.';
      case 'Kidney':
        return 'Many labs consider eGFR at or above about 90 mL/min/1.73m2 reassuring when other kidney markers are normal, while persistently lower values may need review. Age, muscle mass, hydration, and repeat testing affect interpretation.';
      case 'Lungs':
        return 'SpO2 is commonly expected around 95-100% in many healthy adults at sea level, but altitude, circulation, device quality, skin perfusion, and illness can affect readings. Persistent readings below your expected range should be discussed clinically.';
      case 'Brain / Metabolic':
        return 'TyG uses fasting glucose and triglycerides; cutoffs vary across studies and populations. Compare glucose and lipid values with your lab report ranges and interpret the index as a metabolic screening clue.';
      case 'Inflammation':
        return 'NLR does not have one universal diagnostic cutoff. CBC reference ranges vary by lab, age, and clinical context. A persistent change, very high value, or abnormal CBC with symptoms should be reviewed.';
      case 'Pancreas':
        return 'Lipase and amylase ranges vary by laboratory method. A ratio can add context, but the individual enzyme levels, symptoms, timing, and clinical examination are more important for medical decisions.';
      case 'Cancer Awareness':
        return 'AFP, CA 15-3, and CA 27.29 reference ranges depend on the lab and clinical reason for testing. Marker values should be interpreted only with a qualified professional because benign conditions can affect them.';
      default:
        return 'Always compare values with the reference range printed on your report and discuss persistent abnormalities with a qualified healthcare professional.';
    }
  }

  String _healthTipsFor(String organ) {
    switch (organ) {
      case 'Heart':
        return 'Track blood pressure when advised, keep movement regular, avoid tobacco exposure, and review lipids periodically if you have risk factors. Symptoms such as chest pressure, severe breathlessness, fainting, or pain spreading to the arm or jaw need urgent care.';
      case 'Liver':
        return 'Keep alcohol exposure low, maintain a sustainable weight pattern, stay active, and repeat abnormal liver tests as advised. Seek care for jaundice, dark urine, severe abdominal swelling, vomiting blood, or confusion.';
      case 'Kidney':
        return 'Monitor blood pressure and glucose when relevant, avoid dehydration, and use over-the-counter pain medicines carefully. Swelling, reduced urination, blood in urine, or repeated low eGFR should be reviewed promptly.';
      case 'Lungs':
        return 'Avoid smoking and passive smoke, ventilate cooking areas, reduce dust exposure, and pace activity if symptoms occur. Severe shortness of breath, blue lips, chest pain, or very low oxygen readings require urgent attention.';
      case 'Brain / Metabolic':
        return 'Consistent sleep, daily movement, stress regulation, and reducing sugary drinks can improve metabolic patterns over time. Watch for excessive thirst, frequent urination, unexplained weight change, or persistent fatigue.';
      case 'Inflammation':
        return 'Recover fully from infections, prioritize sleep, avoid smoke exposure, and do not overinterpret one CBC ratio. Fever, unexplained weight loss, persistent pain, or repeated abnormal CBC results deserve clinical review.';
      case 'Pancreas':
        return 'Protect metabolic health, limit alcohol exposure, and seek care for severe upper abdominal pain, persistent vomiting, fever, or pain radiating to the back. Enzyme trends should be interpreted by a clinician.';
      case 'Cancer Awareness':
        return 'Follow age-appropriate screening recommended by your clinician, avoid tobacco, protect against unsafe occupational exposures, and bring marker results to appointments. Persistent unexplained symptoms deserve medical evaluation.';
      default:
        return 'Use screening insights as prompts for healthier routines and better clinical conversations.';
    }
  }

  String _personalizedSummaryFor(String organ) {
    switch (organ) {
      case 'Heart':
        return 'For heart-related insights, VitalMap combines your lipid values with lifestyle context such as smoking, activity, sleep, stress, diet, and family history. The goal is to help you notice whether your current pattern looks reassuring, worth monitoring, or worth discussing with a clinician.';
      case 'Liver':
        return 'For liver insights, VitalMap looks at available enzymes, platelets, albumin, body measurements, glucose pattern, and habits such as alcohol, diet, and activity. The summary is a screening explanation that can help you prepare better follow-up questions.';
      case 'Kidney':
        return 'For kidney insights, VitalMap uses creatinine with age and sex to estimate filtration, then presents the result with hydration and safety context. It is most useful when paired with repeat testing and clinician review if values are persistently unusual.';
      case 'Lungs':
        return 'For lung insights, VitalMap treats oxygen saturation alongside exposure answers like smoking, passive smoke, air pollution, dust, and cooking smoke. The app can explain a pattern, but breathing symptoms should always guide real-world urgency.';
      case 'Brain / Metabolic':
        return 'For metabolic insights, VitalMap links glucose, triglycerides, waist pattern, activity, sleep, stress, and food habits. The purpose is to translate report numbers into practical next steps without labeling you with a disease.';
      case 'Inflammation':
        return 'For inflammation insights, VitalMap uses CBC-derived patterns and general health answers to explain possible contributors. Because inflammation markers are broad, the most useful next step is watching trends and symptoms rather than reacting to one value.';
      case 'Pancreas':
        return 'For pancreas insights, VitalMap explains enzyme patterns and metabolic contributors in plain language. It is designed to support awareness and follow-up, especially when digestive symptoms or persistent enzyme changes are present.';
      case 'Cancer Awareness':
        return 'For cancer awareness markers, VitalMap stays intentionally conservative. It can organize marker values, explain why medical review matters, and remind you that these values do not confirm cancer on their own.';
      default:
        return 'VitalMap personalizes insights from the values you enter and the habits you report, while keeping medical decisions with qualified professionals.';
    }
  }

  Widget _infoBlock(BuildContext context, String title, String content) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        iconColor: Theme.of(context).colorScheme.primary,
        collapsedIconColor: Theme.of(context).colorScheme.onSurfaceVariant,
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(bottom: 16),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
