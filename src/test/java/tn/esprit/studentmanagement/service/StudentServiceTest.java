package tn.esprit.studentmanagement.services;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import tn.esprit.studentmanagement.entities.Student;
import tn.esprit.studentmanagement.repositories.StudentRepository;

import java.util.Arrays;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class StudentServiceTest {

    @Mock
    private StudentRepository studentRepository;

    @InjectMocks
    private StudentService studentService;

    private Student student;

    @BeforeEach
    void setUp() {
        student = new Student();
        student.setIdStudent(1L);
        student.setFirstName("John");
        student.setLastName("Doe");
    }

    @Test
    void testSaveStudent() {
        // Given
        when(studentRepository.save(any(Student.class))).thenReturn(student);

        // When
        Student result = studentService.saveStudent(student);

        // Then
        assertNotNull(result);
        assertEquals("John", result.getFirstName());
        verify(studentRepository, times(1)).save(student);
    }

    @Test
    void testGetAllStudents() {
        // Given
        List<Student> students = Arrays.asList(student);
        when(studentRepository.findAll()).thenReturn(students);

        // When
        List<Student> result = studentService.getAllStudents();

        // Then
        assertNotNull(result);
        assertEquals(1, result.size());
        verify(studentRepository, times(1)).findAll();
    }

    @Test
    void testGetStudentById() {
        // Given
        when(studentRepository.findById(1L)).thenReturn(Optional.of(student));

        // When
        Student result = studentService.getStudentById(1L);

        // Then
        assertNotNull(result);
        assertEquals("John", result.getFirstName());
        verify(studentRepository, times(1)).findById(1L);
    }

    @Test
    void testDeleteStudent() {
        // Given
        doNothing().when(studentRepository).deleteById(1L);

        // When
        studentService.deleteStudent(1L);

        // Then
        verify(studentRepository, times(1)).deleteById(1L);
    }
}