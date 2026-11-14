package com.familyvoice.app

import android.graphics.Bitmap
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Button
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

/**
 * 시연용 한 단계.
 * @param needsGear 사람이 에뮬레이터에서 직접 바꿔야 하는 기어 ("D" 또는 "P"). null이면 앱이 알아서 하는 단계.
 */
data class DemoStep(
    val title: String,
    val detail: String,
    val needsGear: String? = null,
    /**
     * true 면 이 단계로 넘어오는 순간 앱이 알아서 실행한다.
     * 주행(기어 D) 중에는 Pleos 가 안전을 위해 화면을 잠가서 버튼을 누를 수 없기 때문에,
     * 달리는 동안 일어나는 단계는 반드시 이렇게 자동으로 돌아야 한다.
     */
    val auto: Boolean = false
)

/**
 * 시연 패널 (전체 화면).
 * 왼쪽에 단계 목록, 오른쪽에 지금 할 일과 QR을 보여준다.
 *
 * @param current 지금 진행할 단계 번호. steps.size 와 같으면 전부 끝난 것.
 * @param waiting 사람이 기어를 바꿔 주기를 기다리는 중인지
 */
@Composable
fun DemoScreen(
    steps: List<DemoStep>,
    current: Int,
    status: String,
    gearNow: String,
    waiting: Boolean,
    qr: Bitmap?,
    qrUrl: String?,
    onNext: () -> Unit,
    onSkip: () -> Unit,
    onReset: () -> Unit,
    onStage: () -> Unit,
    onClose: () -> Unit
) {
    val done = current >= steps.size
    val step = steps.getOrNull(current)

    Row(modifier = Modifier.fillMaxSize().padding(28.dp), horizontalArrangement = Arrangement.spacedBy(28.dp)) {

        // 왼쪽: 단계 목록
        Column(
            modifier = Modifier.width(420.dp).verticalScroll(rememberScrollState()),
            verticalArrangement = Arrangement.spacedBy(10.dp)
        ) {
            Text("시연 순서", style = MaterialTheme.typography.headlineSmall, fontWeight = FontWeight.Bold)
            steps.forEachIndexed { i, s ->
                val isDone = i < current
                val isNow = i == current
                Row(
                    verticalAlignment = Alignment.Top,
                    horizontalArrangement = Arrangement.spacedBy(10.dp),
                    modifier = Modifier
                        .fillMaxWidth()
                        .clip(RoundedCornerShape(10.dp))
                        .background(if (isNow) MaterialTheme.colorScheme.secondaryContainer else Color.Transparent)
                        .padding(10.dp)
                ) {
                    Box(
                        modifier = Modifier.size(22.dp).clip(CircleShape)
                            .background(
                                when {
                                    isDone -> MaterialTheme.colorScheme.primary
                                    isNow -> MaterialTheme.colorScheme.onSecondaryContainer
                                    else -> Color.Transparent
                                }
                            )
                            .border(1.dp, MaterialTheme.colorScheme.outline, CircleShape),
                        contentAlignment = Alignment.Center
                    ) {
                        Text(
                            if (isDone) "✓" else "${i + 1}",
                            fontSize = 12.sp,
                            color = if (isDone || isNow) MaterialTheme.colorScheme.surface
                            else MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                    Column {
                        Text(
                            s.title,
                            style = MaterialTheme.typography.titleMedium,
                            fontWeight = if (isNow) FontWeight.Bold else FontWeight.Normal
                        )
                        if (isNow) Text(s.detail, style = MaterialTheme.typography.bodyMedium)
                        if (s.needsGear != null) {
                            Text(
                                "에뮬레이터에서 기어 ${s.needsGear}",
                                style = MaterialTheme.typography.bodySmall,
                                color = MaterialTheme.colorScheme.primary
                            )
                        }
                    }
                }
            }
        }

        // 오른쪽: 지금 할 일
        Column(
            modifier = Modifier.fillMaxSize().verticalScroll(rememberScrollState()),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            Row(horizontalArrangement = Arrangement.spacedBy(12.dp), verticalAlignment = Alignment.CenterVertically) {
                OutlinedButton(onClick = onClose) { Text("← 나가기") }
                OutlinedButton(onClick = onReset) { Text("처음으로 되돌리기") }
                Button(onClick = onStage) { Text("무대 모드 (영상용)") }
                Text("기어 $gearNow", style = MaterialTheme.typography.titleMedium)
            }

            if (done) {
                Text("시연이 끝났어요", style = MaterialTheme.typography.headlineMedium, fontWeight = FontWeight.Bold)
                Text("다시 찍으려면 '처음으로 되돌리기'를 누르세요.", style = MaterialTheme.typography.bodyLarge)
            } else if (step != null) {
                Text("${current + 1}. ${step.title}", style = MaterialTheme.typography.headlineMedium, fontWeight = FontWeight.Bold)
                Text(step.detail, style = MaterialTheme.typography.bodyLarge)

                if (step.needsGear != null) {
                    Text(
                        if (waiting) "에뮬레이터에서 기어를 ${step.needsGear}로 바꿔 주세요. 바뀌면 자동으로 넘어가요."
                        else "준비되면 시작을 누르세요.",
                        style = MaterialTheme.typography.titleMedium,
                        color = MaterialTheme.colorScheme.primary
                    )
                    Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                        if (!waiting) Button(onClick = onNext) { Text("시작") }
                        OutlinedButton(onClick = onSkip) { Text("건너뛰기 (기어 없이 진행)") }
                    }
                } else {
                    Button(onClick = onNext) { Text("다음 단계", style = MaterialTheme.typography.titleLarge) }
                }
            }

            if (status.isNotEmpty()) {
                Text(status, style = MaterialTheme.typography.bodyLarge)
            }

            if (qr != null) {
                Text("동승자 폰으로 찍어 주세요", style = MaterialTheme.typography.titleMedium)
                Image(bitmap = qr.asImageBitmap(), contentDescription = "사진 업로드 QR", modifier = Modifier.size(280.dp))
                if (qrUrl != null) Text(qrUrl, style = MaterialTheme.typography.bodySmall)
            }
        }
    }
}

/**
 * 무대 모드 띠.
 * 영상에 담을 때 쓰는 모습 — 실제 앱 화면(기억 지도·질문 카드·회상 카드)이 그대로 보이고,
 * 아래쪽에 얇은 띠로만 지금 단계와 버튼이 뜬다.
 *
 * 주행 중(기어 D)에는 Pleos 가 화면을 잠그기 때문에 이 띠의 버튼도 눌리지 않는다.
 * 그래서 달리는 동안의 단계는 auto 로 두어 저절로 진행되게 해야 한다.
 */
@Composable
fun DemoStageBar(
    steps: List<DemoStep>,
    current: Int,
    status: String,
    waiting: Boolean,
    onNext: () -> Unit,
    onSkip: () -> Unit,
    onShowList: () -> Unit
) {
    val step = steps.getOrNull(current)
    Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.BottomCenter) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp)
                .clip(RoundedCornerShape(14.dp))
                .background(Color(0xCC101014))
                .padding(horizontal = 18.dp, vertical = 12.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            Column(modifier = Modifier.weight(1f)) {
                Text(
                    if (step == null) "시연 끝" else "${current + 1}/${steps.size} · ${step.title}",
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold,
                    color = Color.White
                )
                val line = when {
                    status.isNotEmpty() -> status
                    step?.needsGear != null -> "기어를 ${step.needsGear}로 바꿔 주세요"
                    else -> step?.detail ?: ""
                }
                if (line.isNotEmpty()) {
                    Text(line, style = MaterialTheme.typography.bodyMedium, color = Color(0xFFBFC4CC))
                }
            }
            if (step != null) {
                if (step.needsGear != null) {
                    if (!waiting) Button(onClick = onNext) { Text("시작") }
                    OutlinedButton(onClick = onSkip) { Text("건너뛰기") }
                } else if (!step.auto) {
                    Button(onClick = onNext) { Text("다음") }
                }
            }
            OutlinedButton(onClick = onShowList) { Text("목록") }
        }
    }
}
