from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):

    dependencies = [
        ('filieres', '0001_initial'),
        ('matieres', '0001_initial'),
        ('exams', '0001_initial'),
    ]

    operations = [
        migrations.RenameModel(
            old_name='Epreuve',
            new_name='Document',
        ),
        migrations.AddField(
            model_name='document',
            name='couverture',
            field=models.ImageField(blank=True, null=True, upload_to='couvertures/', verbose_name='Photo de couverture'),
        ),
        migrations.AlterModelOptions(
            name='document',
            options={'ordering': ['-created_at'], 'verbose_name': 'Document', 'verbose_name_plural': 'Documents'},
        ),
        migrations.AlterModelTable(
            name='document',
            table='exams_epreuve',
        ),
        migrations.AlterField(
            model_name='document',
            name='filiere',
            field=models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='documents', to='filieres.filiere'),
        ),
        migrations.AlterField(
            model_name='document',
            name='matiere',
            field=models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='documents', to='matieres.matiere'),
        ),
        migrations.AlterField(
            model_name='document',
            name='type_contenu',
            field=models.CharField(choices=[('EXAM', 'Examen'), ('TD', 'Travaux dirigés'), ('CORRECTION', 'Corrigé'), ('COURSE', 'Support de cours'), ('DOCUMENT', 'Autre document')], default='EXAM', max_length=15),
        ),
    ]
