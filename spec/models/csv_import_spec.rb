require 'rails_helper'

RSpec.describe CsvImport, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:status) }
    it { should validate_presence_of(:file_path) }
    it { should validate_inclusion_of(:status).in_array(CsvImport::STATUSES) }
  end

  describe 'scopes' do
    let!(:pending_import) { create(:csv_import, :pending) }
    let!(:processing_import) { create(:csv_import, :processing) }
    let!(:completed_import) { create(:csv_import, :completed) }
    let!(:failed_import) { create(:csv_import, :failed) }

    describe '.pending' do
      it 'returns only pending imports' do
        expect(CsvImport.pending).to include(pending_import)
        expect(CsvImport.pending).not_to include(processing_import, completed_import, failed_import)
      end
    end

    describe '.processing' do
      it 'returns only processing imports' do
        expect(CsvImport.processing).to include(processing_import)
        expect(CsvImport.processing).not_to include(pending_import, completed_import, failed_import)
      end
    end

    describe '.completed' do
      it 'returns only completed imports' do
        expect(CsvImport.completed).to include(completed_import)
        expect(CsvImport.completed).not_to include(pending_import, processing_import, failed_import)
      end
    end

    describe '.failed' do
      it 'returns only failed imports' do
        expect(CsvImport.failed).to include(failed_import)
        expect(CsvImport.failed).not_to include(pending_import, processing_import, completed_import)
      end
    end

    describe '.recent' do
      it 'orders by created_at descending' do
        oldest = create(:csv_import, created_at: 1.day.ago)
        newest = create(:csv_import, created_at: Time.current)

        recent = CsvImport.recent.limit(2)
        expect(recent.first).to eq(newest)
      end
    end
  end

  describe 'status methods' do
    describe '#pending?' do
      it 'returns true when status is pending' do
        import = build(:csv_import, :pending)
        expect(import.pending?).to be true
      end

      it 'returns false otherwise' do
        import = build(:csv_import, :processing)
        expect(import.pending?).to be false
      end
    end

    describe '#processing?' do
      it 'returns true when status is processing' do
        import = build(:csv_import, :processing)
        expect(import.processing?).to be true
      end
    end

    describe '#completed?' do
      it 'returns true when status is completed' do
        import = build(:csv_import, :completed)
        expect(import.completed?).to be true
      end
    end

    describe '#failed?' do
      it 'returns true when status is failed' do
        import = build(:csv_import, :failed)
        expect(import.failed?).to be true
      end
    end
  end

  describe 'state transitions' do
    describe '#start_processing!' do
      let(:import) { create(:csv_import, :pending) }

      it 'changes status to processing' do
        import.start_processing!
        expect(import.status).to eq('processing')
      end

      it 'sets started_at timestamp' do
        freeze_time do
          import.start_processing!
          expect(import.started_at).to eq(Time.current)
        end
      end
    end

    describe '#complete!' do
      let(:import) { create(:csv_import, :processing) }

      it 'changes status to completed' do
        import.complete!(employees_created: 10, responses_created: 50)
        expect(import.status).to eq('completed')
      end

      it 'sets results' do
        import.complete!(employees_created: 10, responses_created: 50, import_errors: [{ line: 1, error: 'test' }])
        expect(import.employees_created).to eq(10)
        expect(import.responses_created).to eq(50)
        expect(import.import_errors).to eq([{ 'line' => 1, 'error' => 'test' }])
      end

      it 'sets completed_at timestamp' do
        freeze_time do
          import.complete!(employees_created: 10, responses_created: 50)
          expect(import.completed_at).to eq(Time.current)
        end
      end
    end

    describe '#fail!' do
      let(:import) { create(:csv_import, :processing) }

      it 'changes status to failed' do
        import.fail!('Something went wrong')
        expect(import.status).to eq('failed')
      end

      it 'sets error_message' do
        import.fail!('Something went wrong')
        expect(import.error_message).to eq('Something went wrong')
      end

      it 'sets completed_at timestamp' do
        freeze_time do
          import.fail!('Error')
          expect(import.completed_at).to eq(Time.current)
        end
      end
    end

    describe '#update_progress!' do
      let(:import) { create(:csv_import, :processing) }

      it 'updates processed_rows' do
        import.update_progress!(processed_rows: 50)
        expect(import.processed_rows).to eq(50)
      end

      it 'optionally updates total_rows' do
        import.update_progress!(processed_rows: 50, total_rows: 100)
        expect(import.total_rows).to eq(100)
      end
    end
  end

  describe 'computed methods' do
    describe '#progress_percentage' do
      it 'returns 0 when total_rows is zero' do
        import = build(:csv_import, total_rows: 0, processed_rows: 0)
        expect(import.progress_percentage).to eq(0)
      end

      it 'calculates percentage correctly' do
        import = build(:csv_import, total_rows: 100, processed_rows: 25)
        expect(import.progress_percentage).to eq(25.0)
      end

      it 'rounds to one decimal place' do
        import = build(:csv_import, total_rows: 300, processed_rows: 100)
        expect(import.progress_percentage).to eq(33.3)
      end
    end

    describe '#duration' do
      it 'returns nil when started_at is nil' do
        import = build(:csv_import, started_at: nil)
        expect(import.duration).to be_nil
      end

      it 'calculates duration using completed_at when present' do
        import = build(:csv_import, started_at: 5.minutes.ago, completed_at: Time.current)
        expect(import.duration).to be_within(1).of(300) # 5 minutes in seconds
      end

      it 'calculates duration using current time when not completed' do
        import = build(:csv_import, started_at: 2.minutes.ago, completed_at: nil)
        expect(import.duration).to be_within(1).of(120) # 2 minutes in seconds
      end
    end

    describe '#duration_in_words' do
      it 'returns nil when duration is nil' do
        import = build(:csv_import, started_at: nil)
        expect(import.duration_in_words).to be_nil
      end

      it 'returns seconds for durations less than 60 seconds' do
        import = build(:csv_import, started_at: 30.seconds.ago, completed_at: Time.current)
        expect(import.duration_in_words).to include('30')
      end

      it 'returns minutes for durations less than 1 hour' do
        import = build(:csv_import, started_at: 5.minutes.ago, completed_at: Time.current)
        expect(import.duration_in_words).to include('5')
      end

      it 'returns hours for durations 1 hour or more' do
        import = build(:csv_import, started_at: 2.hours.ago, completed_at: Time.current)
        expect(import.duration_in_words).to include('2')
      end
    end

    describe '#has_import_errors?' do
      it 'returns true when import_errors has items' do
        import = build(:csv_import, :completed_with_errors)
        expect(import.has_import_errors?).to be true
      end

      it 'returns false when import_errors is empty' do
        import = build(:csv_import, :completed)
        expect(import.has_import_errors?).to be false
      end

      it 'returns false when import_errors is nil' do
        import = build(:csv_import, import_errors: nil)
        expect(import.has_import_errors?).to be false
      end
    end

    describe '#status_label' do
      it 'returns translated status' do
        import = build(:csv_import, :pending)
        expect(import.status_label).to be_present
      end
    end
  end
end
