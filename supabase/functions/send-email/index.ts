/// <reference lib="deno.window" />

// Helper function to create CORS headers
const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, Authorization",
};

// Email template generators
function generateWelcomeEmail(data: {
  clientName: string;
  lawyerName: string;
  caseRef: string;
}): string {
  return `
    <!DOCTYPE html>
    <html>
      <head>
        <meta charset="UTF-8">
        <style>
          body { font-family: Arial, sans-serif; color: #333; }
          .container { max-width: 600px; margin: 0 auto; padding: 20px; }
          .header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 30px; text-align: center; border-radius: 8px 8px 0 0; }
          .content { background: #f9fafb; padding: 30px; border-radius: 0 0 8px 8px; }
          .footer { text-align: center; color: #666; font-size: 12px; margin-top: 20px; }
          .button { display: inline-block; background: #667eea; color: white; padding: 12px 30px; text-decoration: none; border-radius: 5px; margin: 20px 0; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h1>Welcome to LegalSync</h1>
          </div>
          <div class="content">
            <p>Hello <strong>${data.clientName}</strong>,</p>
            <p>Welcome to LegalSync! Your lawyer <strong>${data.lawyerName}</strong> has invited you to manage your legal case more efficiently.</p>
            <p><strong>Case Reference:</strong> ${data.caseRef}</p>
            <p>With LegalSync, you can:</p>
            <ul>
              <li>Track your case progress in real-time</li>
              <li>Securely share and store important documents</li>
              <li>Receive timely updates and reminders</li>
              <li>Communicate directly with your lawyer</li>
            </ul>
            <p>If you have any questions, please contact ${data.lawyerName} directly.</p>
            <p>Best regards,<br>The LegalSync Team</p>
          </div>
          <div class="footer">
            <p>&copy; 2024 LegalSync. All rights reserved.</p>
          </div>
        </div>
      </body>
    </html>
  `;
}

function generateHearingScheduledEmail(data: {
  clientName: string;
  lawyerName: string;
  caseTitle: string;
  date: string;
  time: string;
  court: string;
}): string {
  return `
    <!DOCTYPE html>
    <html>
      <head>
        <meta charset="UTF-8">
        <style>
          body { font-family: Arial, sans-serif; color: #333; }
          .container { max-width: 600px; margin: 0 auto; padding: 20px; }
          .header { background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%); color: white; padding: 30px; text-align: center; border-radius: 8px 8px 0 0; }
          .content { background: #f9fafb; padding: 30px; border-radius: 0 0 8px 8px; }
          .details-box { background: white; border-left: 4px solid #f5576c; padding: 15px; margin: 20px 0; }
          .detail-row { margin: 10px 0; font-size: 15px; }
          .footer { text-align: center; color: #666; font-size: 12px; margin-top: 20px; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h1>🗓️ Hearing Scheduled</h1>
          </div>
          <div class="content">
            <p>Dear <strong>${data.clientName}</strong>,</p>
            <p>Your hearing for <strong>${data.caseTitle}</strong> has been scheduled. Please see the details below:</p>
            <div class="details-box">
              <div class="detail-row"><strong>📅 Date:</strong> ${data.date}</div>
              <div class="detail-row"><strong>⏰ Time:</strong> ${data.time}</div>
              <div class="detail-row"><strong>📍 Location:</strong> ${data.court}</div>
            </div>
            <p>Please make sure to:</p>
            <ul>
              <li>Mark this date and time on your calendar</li>
              <li>Arrive at least 15 minutes early</li>
              <li>Bring all relevant documents</li>
              <li>Contact <strong>${data.lawyerName}</strong> if you have any questions</li>
            </ul>
            <p>Best regards,<br><strong>${data.lawyerName}</strong></p>
          </div>
          <div class="footer">
            <p>&copy; 2024 LegalSync. All rights reserved.</p>
          </div>
        </div>
      </body>
    </html>
  `;
}

function generateHearingReminderEmail(data: {
  clientName: string;
  lawyerName: string;
  date: string;
  time: string;
  court: string;
}): string {
  return `
    <!DOCTYPE html>
    <html>
      <head>
        <meta charset="UTF-8">
        <style>
          body { font-family: Arial, sans-serif; color: #333; }
          .container { max-width: 600px; margin: 0 auto; padding: 20px; }
          .header { background: linear-gradient(135deg, #fa709a 0%, #fee140 100%); color: #333; padding: 30px; text-align: center; border-radius: 8px 8px 0 0; }
          .content { background: #f9fafb; padding: 30px; border-radius: 0 0 8px 8px; }
          .alert-box { background: #fef3c7; border-left: 4px solid #f59e0b; padding: 15px; margin: 20px 0; border-radius: 4px; }
          .footer { text-align: center; color: #666; font-size: 12px; margin-top: 20px; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h1>⚠️ Hearing Reminder</h1>
          </div>
          <div class="content">
            <p>Dear <strong>${data.clientName}</strong>,</p>
            <p>This is a reminder that your hearing is <strong>tomorrow</strong>.</p>
            <div class="alert-box">
              <p><strong>Hearing Details:</strong></p>
              <p>📅 <strong>Date:</strong> ${data.date}</p>
              <p>⏰ <strong>Time:</strong> ${data.time}</p>
              <p>📍 <strong>Location:</strong> ${data.court}</p>
            </div>
            <p>Make sure you:</p>
            <ul>
              <li>Have all the required documents ready</li>
              <li>Get a good night's sleep</li>
              <li>Plan your travel to arrive on time</li>
              <li>Contact <strong>${data.lawyerName}</strong> immediately if you have any concerns</li>
            </ul>
            <p>We wish you the best of luck!</p>
            <p>Best regards,<br><strong>${data.lawyerName}</strong></p>
          </div>
          <div class="footer">
            <p>&copy; 2024 LegalSync. All rights reserved.</p>
          </div>
        </div>
      </body>
    </html>
  `;
}

function generateCaseUpdateEmail(data: {
  clientName: string;
  lawyerName: string;
  caseTitle: string;
  updateText: string;
}): string {
  return `
    <!DOCTYPE html>
    <html>
      <head>
        <meta charset="UTF-8">
        <style>
          body { font-family: Arial, sans-serif; color: #333; }
          .container { max-width: 600px; margin: 0 auto; padding: 20px; }
          .header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 30px; text-align: center; border-radius: 8px 8px 0 0; }
          .content { background: #f9fafb; padding: 30px; border-radius: 0 0 8px 8px; }
          .update-box { background: white; border-left: 4px solid #667eea; padding: 20px; margin: 20px 0; border-radius: 4px; }
          .footer { text-align: center; color: #666; font-size: 12px; margin-top: 20px; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h1>📋 Case Update</h1>
          </div>
          <div class="content">
            <p>Dear <strong>${data.clientName}</strong>,</p>
            <p>There is an important update regarding <strong>${data.caseTitle}</strong>:</p>
            <div class="update-box">
              <p>${data.updateText}</p>
            </div>
            <p>If you have any questions about this update, please don't hesitate to contact <strong>${data.lawyerName}</strong>.</p>
            <p>Log in to LegalSync to see all case details and documentation.</p>
            <p>Best regards,<br><strong>${data.lawyerName}</strong></p>
          </div>
          <div class="footer">
            <p>&copy; 2024 LegalSync. All rights reserved.</p>
          </div>
        </div>
      </body>
    </html>
  `;
}

function generateDocumentSharedEmail(data: {
  clientName: string;
  lawyerName: string;
  documentName: string;
}): string {
  return `
    <!DOCTYPE html>
    <html>
      <head>
        <meta charset="UTF-8">
        <style>
          body { font-family: Arial, sans-serif; color: #333; }
          .container { max-width: 600px; margin: 0 auto; padding: 20px; }
          .header { background: linear-gradient(135deg, #4facfe 0%, #00f2fe 100%); color: white; padding: 30px; text-align: center; border-radius: 8px 8px 0 0; }
          .content { background: #f9fafb; padding: 30px; border-radius: 0 0 8px 8px; }
          .document-box { background: white; border-left: 4px solid #00f2fe; padding: 20px; margin: 20px 0; border-radius: 4px; text-align: center; }
          .footer { text-align: center; color: #666; font-size: 12px; margin-top: 20px; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h1>📄 Document Shared</h1>
          </div>
          <div class="content">
            <p>Dear <strong>${data.clientName}</strong>,</p>
            <p><strong>${data.lawyerName}</strong> has shared a new document with you:</p>
            <div class="document-box">
              <p style="font-size: 18px; font-weight: bold;">${data.documentName}</p>
              <p style="color: #666; font-size: 14px;">Shared on ${new Date().toLocaleDateString()}</p>
            </div>
            <p>You can now access this document securely through LegalSync. Log in to your account to view and download it.</p>
            <p>If you have any questions about this document, please contact <strong>${data.lawyerName}</strong>.</p>
            <p>Best regards,<br><strong>${data.lawyerName}</strong></p>
          </div>
          <div class="footer">
            <p>&copy; 2024 LegalSync. All rights reserved.</p>
          </div>
        </div>
      </body>
    </html>
  `;
}

// Email template router
function getEmailTemplate(
  type: string,
  data: Record<string, unknown>
): { html: string; subject: string } | null {
  switch (type) {
    case "welcome":
      return {
        html: generateWelcomeEmail(data as {
          clientName: string;
          lawyerName: string;
          caseRef: string;
        }),
        subject: "Welcome to LegalSync",
      };
    case "hearing_scheduled":
      return {
        html: generateHearingScheduledEmail(data as {
          clientName: string;
          lawyerName: string;
          caseTitle: string;
          date: string;
          time: string;
          court: string;
        }),
        subject: `Hearing Scheduled — ${(data as { date?: string }).date || ""}`,
      };
    case "hearing_reminder":
      return {
        html: generateHearingReminderEmail(data as {
          clientName: string;
          lawyerName: string;
          date: string;
          time: string;
          court: string;
        }),
        subject: "Reminder — Hearing Tomorrow",
      };
    case "case_update":
      return {
        html: generateCaseUpdateEmail(data as {
          clientName: string;
          lawyerName: string;
          caseTitle: string;
          updateText: string;
        }),
        subject: `Case Update — ${(data as { caseTitle?: string }).caseTitle || ""}`,
      };
    case "document_shared":
      return {
        html: generateDocumentSharedEmail(data as {
          clientName: string;
          lawyerName: string;
          documentName: string;
        }),
        subject: "New Document Shared",
      };
    default:
      return null;
  }
}

// Main handler
Deno.serve(async (req: Request) => {
  // Handle CORS preflight requests
  if (req.method === "OPTIONS") {
    return new Response(null, {
      status: 204,
      headers: corsHeaders,
    });
  }

  // Only allow POST requests
  if (req.method !== "POST") {
    return new Response(JSON.stringify({ success: false, error: "Method not allowed" }), {
      status: 405,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  try {
    // Parse request body
    const { to, _subject, type, data } = await req.json();

    // Validate required fields
    if (!to || !type || !data) {
      return new Response(
        JSON.stringify({
          success: false,
          error: "Missing required fields: to, type, data",
        }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Get the email template
    const emailTemplate = getEmailTemplate(type, data);
    if (!emailTemplate) {
      return new Response(
        JSON.stringify({
          success: false,
          error: `Unknown email type: ${type}`,
        }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Get API key from environment
    const apiKey = Deno.env.get("RESEND_API_KEY");
    if (!apiKey) {
      console.error("RESEND_API_KEY not configured");
      return new Response(
        JSON.stringify({
          success: false,
          error: "Server configuration error",
        }),
        {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Send email via Resend API
    const response = await fetch("https://api.resend.com/emails", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${apiKey}`,
      },
      body: JSON.stringify({
        from: "LegalSync <onboarding@resend.dev>",
        to: to,
        subject: emailTemplate.subject,
        html: emailTemplate.html,
      }),
    });

    const resendResponse = await response.json();

    if (!response.ok) {
      console.error("Resend API error:", resendResponse);
      return new Response(
        JSON.stringify({
          success: false,
          error: "Failed to send email",
        }),
        {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    return new Response(
      JSON.stringify({
        success: true,
        message: "Email sent successfully",
        id: resendResponse.id,
      }),
      {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  } catch (error) {
    console.error("Edge function error:", error);
    return new Response(
      JSON.stringify({
        success: false,
        error: "Internal server error",
      }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }
});