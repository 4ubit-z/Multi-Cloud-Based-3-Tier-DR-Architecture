from celery import shared_task
from .models import Post

@shared_task
def log_new_post(post_id):
    post = Post.objects.get(id=post_id)
    print(f"[CELERY] New post created: {post.title}")
