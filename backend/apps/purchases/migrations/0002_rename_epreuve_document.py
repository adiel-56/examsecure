from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):

    dependencies = [
        ('exams', '0002_document_add_couverture'),
        ('purchases', '0001_initial'),
    ]

    operations = [
        migrations.RenameField(
            model_name='achat',
            old_name='epreuve',
            new_name='document',
        ),
        migrations.AlterField(
            model_name='achat',
            name='document',
            field=models.ForeignKey(db_column='epreuve_id', on_delete=django.db.models.deletion.CASCADE, related_name='achats', to='exams.document'),
        ),
        migrations.AlterModelOptions(
            name='achat',
            options={'ordering': ['-created_at'], 'verbose_name': 'Achat', 'verbose_name_plural': 'Achats'},
        ),
    ]
