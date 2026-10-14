# AI Dev — פתיחה וסגירה

## פרטי השירות

- כתובת API: https://ai-dev.grossmanbot.download
- שירות Tunnel: `cloudflared-ai-dev`
- קונטיינר מודל: `qwen-api`
- מודל: `Qwen/Qwen3-4B-AWQ`
- API מקומי: http://127.0.0.1:8000
- הגישה מבחוץ דורשת Service Token תקין ו-IP ציבורי `34.173.200.67`.

הפקודות לניהול השירות רצות במחשב הביתי, לאחר יצירת שירות systemd.

## סגירת הגישה מבחוץ

```bash
sudo systemctl stop cloudflared-ai-dev
```

המודל ממשיך לעבוד מקומית. אם השירות enabled, ה-Tunnel יחזור באתחול הבא.

## פתיחת הגישה

```bash
sudo systemctl start cloudflared-ai-dev
```

## סגירה וביטול הפעלה אוטומטית

```bash
sudo systemctl disable --now cloudflared-ai-dev
```

## פתיחה והפעלה אוטומטית באתחול

```bash
sudo systemctl enable --now cloudflared-ai-dev
```

## בדיקות ולוגים

```bash
systemctl is-active cloudflared-ai-dev
systemctl is-enabled cloudflared-ai-dev
sudo systemctl status cloudflared-ai-dev --no-pager
journalctl -u cloudflared-ai-dev -n 50 --no-pager
```

## עצירה והפעלה של המודל

עצירה:

```bash
docker stop qwen-api
```

הפעלה:

```bash
docker start qwen-api
docker logs -f --tail 50 qwen-api
```

המתן לסיום טעינת המודל. Ctrl+C יוצא מצפייה בלוגים בלבד.

בדיקת API מקומי:

```bash
curl -fsS http://127.0.0.1:8000/v1/models
```

עצירת המודל משחררת את זיכרון ה-GPU שלו. הפעלה מחדש דורשת טעינה ל-GPU; קובצי המודל נשארים ב-Volume.

הקונטיינר נוצר עם `--restart unless-stopped`: הוא עולה לאחר אתחול אם לא נעצר ידנית.

## בקשות במקביל

ההגדרה הנוכחית:

```text
--max-num-seqs 4
--max-model-len 4096
--gpu-memory-utilization 0.80
```

- עד 4 רצפים/בקשות פעילות במנוע בתצורה הנוכחית; בקשות נוספות יכולות להמתין בתור.
- זו אינה הגבלה על מספר המשתמשים הרשומים.
- אורך הקלט והפלט יחד מוגבל ל-4,096 טוקנים לבקשה.
- המהירות תלויה באורך הבקשות והתגובות. טרם בוצעה בדיקת עומס.
- מתחילים ב-4 ומודדים זמן תגובה וצריכת זיכרון לפני הגדלה.

## אבטחה

- אין לשתף Client Secret או כותרת Set-Cookie.
- יש להחליף את הטוקן שנחשף בשיחה ולעדכן את ה-Policy.
- אומתה גישה מהשרת עם טוקן (200), וחסימה בלי טוקן (403).
- יש להשלים בדיקה ממחשב אחר עם טוקן תקין כדי לאמת בנפרד את הגבלת ה-IP.
- עצירת השירות הזה אינה עוצרת Tunnels במכונות אחרות.
