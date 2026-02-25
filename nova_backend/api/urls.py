from django.urls import path
from .views import NovaLiteChatView, NovaSonicAudioView, NovaActAgentView, NovaEmbeddingsView

urlpatterns = [
    path('nova-lite/chat/', NovaLiteChatView.as_view(), name='nova_lite_chat'),
    path('nova-sonic/audio/', NovaSonicAudioView.as_view(), name='nova_sonic_audio'),
    path('nova-act/fleet/', NovaActAgentView.as_view(), name='nova_act_fleet'),
    path('nova-embeddings/generate/', NovaEmbeddingsView.as_view(), name='nova_embeddings_generate'),
]
